#!/usr/bin/env python3
"""
Extract per-algorithm documentation fragments from the manual, send each to a local
LLM (OpenAI-compatible Chat Completions API), and write the returned JSON to a
review directory. Also writes the extracted fragment and raw response alongside for tracing.

Usage:
  python3 scripts/extract_algorithms_with_llm.py \
      --manual docs/manual-1.10.0.md \
      --out-dir docs/algorithms_llm_review \
      --base-url http://dev.local:1234/v1/chat/completions \
      --model local-model

Notes:
  - The script only prepares and sends requests; it does not modify existing
    docs/algorithms/*.json files.
  - If your environment lacks network access, run this script locally.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import List, Tuple, Optional, Dict

try:
    import requests  # type: ignore
except Exception:
    requests = None  # For environments without network libs; still allow fragment extraction


ROOT = Path(__file__).resolve().parents[1]

# Regexes to locate algorithms and GUIDs in the manual
HEADER_RE = re.compile(r"^##\s+(.*)")
GUID_RE = re.compile(r"File format guid:\s*['\u2018\u2019\u2032\u2035]?([a-z0-9 ]{4})['\u2019\u2018\u2032\u2035]?")


def normalize_guid(g: str) -> str:
    return g.replace(" ", "").lower()


@dataclass
class AlgoDoc:
    guid: str
    name: str
    start_line: int
    end_line: int
    fragment: str


def find_algorithms(manual_path: Path) -> List[AlgoDoc]:
    """Scan the manual and return a list of algorithms with line spans and fragments."""
    text = manual_path.read_text(encoding="utf-8")
    lines = text.splitlines()

    algos: List[AlgoDoc] = []

    # Approach: iterate lines. When we see a GUID line, look backwards for the most recent ## header
    # to pick the name, and set start at that header line. The end is the next ## header or EOF.
    header_positions: List[Tuple[int, str]] = []
    for idx, line in enumerate(lines):
        m = HEADER_RE.match(line)
        if m:
            header_positions.append((idx, m.group(1).strip()))

    # Build an index of guid occurrences
    guid_positions: List[Tuple[int, str]] = []
    for idx, line in enumerate(lines):
        m = GUID_RE.search(line)
        if m:
            guid_positions.append((idx, normalize_guid(m.group(1))))

    # For each guid occurrence, map to nearest preceding header as the start
    for gidx, (line_no, guid) in enumerate(guid_positions):
        # Find nearest header above this line
        header_line = 0
        header_name = f"{guid}"
        for hline, hname in reversed(header_positions):
            if hline <= line_no:
                header_line, header_name = hline, hname
                break
        # Find end: next header after guid line
        end_line = len(lines) - 1
        for hline, _ in header_positions:
            if hline > line_no:
                end_line = hline - 1
                break
        # Extract fragment
        frag = "\n".join(lines[header_line:end_line + 1]).strip()
        algos.append(AlgoDoc(guid=guid, name=header_name, start_line=header_line + 1, end_line=end_line + 1, fragment=frag))

    # Deduplicate by GUID keeping first occurrence (assumes 1.10 contains latest)
    seen = set()
    unique_algos: List[AlgoDoc] = []
    for a in algos:
        if a.guid in seen:
            continue
        seen.add(a.guid)
        unique_algos.append(a)
    return unique_algos


def default_schema() -> Dict:
    """Return the JSON schema the LLM should adhere to (aligned with existing docs)."""
    return {
        "type": "object",
        "required": ["guid", "name", "categories", "description", "specifications", "parameters", "features", "input_ports", "output_ports"],
        "properties": {
            "guid": {"type": "string", "description": "Exactly 4 characters GUID for the algorithm"},
            "name": {"type": "string"},
            "categories": {"type": "array", "items": {"type": "string"}},
            "description": {"type": "string"},
            "specifications": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {"type": "string"},
                        "unit": {"type": ["string", "null"]},
                        "value": {"type": ["object", "null"]},
                        "min": {},
                        "max": {},
                        "description": {"type": ["string", "null"]},
                    },
                    "additionalProperties": True
                }
            },
            "parameters": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {"type": "string"},
                        "unit": {"type": ["string", "null"]},
                        "min": {},
                        "max": {},
                        "default": {},
                        "defaultValue": {},
                        "scope": {"type": ["string", "null"]},
                        "description": {"type": ["string", "null"]},
                        "enumValues": {"type": ["array", "null"], "items": {"type": "string"}},
                        "type": {"type": ["string", "null"]},
                        "busIdRef": {"type": ["string", "null"]},
                        "channelCountRef": {"type": ["string", "null"]},
                        "isPerChannel": {"type": ["boolean", "null"]},
                        "isCommon": {"type": ["boolean", "null"]}
                    },
                    "additionalProperties": True
                }
            },
            "features": {"type": "array", "items": {"type": "string"}},
            "input_ports": {
                "type": "array",
                "items": {"type": ["object", "string"], "additionalProperties": True}
            },
            "output_ports": {
                "type": "array",
                "items": {"type": ["object", "string"], "additionalProperties": True}
            }
        },
        "additionalProperties": True
    }


def build_prompt(guid: str, name: str, fragment: str, schema: Dict) -> List[Dict[str, str]]:
    instructions = (
        "You are an expert technical writer and structured data extractor. "
        "Extract a complete JSON object for the algorithm described below, adhering strictly to the provided schema. "
        "Do not invent details; only include parameters/specifications explicitly present in the documentation or obvious from headings. "
        "For parameters, preserve names and units as written; include min/max/default where tables provide them. "
        "For routing-related parameters, include them and prefer unit='bus'. "
        "Where the manual lists options (e.g., 'The options are ...'), include them in enumValues. "
        "Add input_ports/output_ports with busIdRef matching the routing parameter names that assign buses. "
        "Return JSON only, with no markdown fencing."
    )
    content = (
        f"Algorithm GUID: {guid}\n"
        f"Name: {name}\n\n"
        f"Schema (JSON Schema):\n{json.dumps(schema, ensure_ascii=False, indent=2)}\n\n"
        f"Documentation fragment:\n{fragment}\n"
    )
    return [
        {"role": "system", "content": instructions},
        {"role": "user", "content": content}
    ]


def call_llm(base_url: str, model: str, messages: List[Dict[str, str]], temperature: float = 0.0, max_tokens: int = 4096, timeout: int = 60) -> str:
    """Try common OpenAI-compatible endpoints in order until one succeeds.

    Supports:
      - Chat Completions:   POST /v1/chat/completions  (messages)
      - Completions:        POST /v1/completions       (prompt)
      - LM Studio variant:  POST /v1/chat/completions  (messages)
      - Fallbacks: try stripping/adding /v1 and /chat suffixes if 404.
    """
    if requests is None:
        raise RuntimeError("The 'requests' library is not available in this environment.")

    def make_prompt_from_messages(msgs: List[Dict[str, str]]) -> str:
        parts = []
        for m in msgs:
            role = m.get("role", "user").upper()
            parts.append(f"[{role}]\n{m.get('content','')}\n")
        return "\n".join(parts)

    # Normalize base URL
    u = base_url.rstrip('/')
    # If the URL looks like a full endpoint (endswith /completions), also derive a root
    root = u
    m = re.match(r"^(.*?/v1)(?:/.*)?$", u)
    if m:
        root = m.group(1)

    def list_models(root_url: str) -> List[str]:
        try:
            r = requests.get(f"{root_url}/models", timeout=timeout)
            if r.status_code == 200:
                data = r.json()
                return [m.get('id') for m in data.get('data', []) if m.get('id')]
        except Exception:
            pass
        return []

    # Try to resolve root and verify model exists
    models = list_models(root)
    eff_model = model
    if models and model not in models:
        eff_model = models[0]

    chat_payload = {
        "model": eff_model,
        "temperature": temperature,
        "messages": messages,
        "max_tokens": max_tokens,
    }
    comp_payload = {
        "model": eff_model,
        "temperature": temperature,
        "prompt": make_prompt_from_messages(messages),
        "max_tokens": max_tokens,
    }
    headers = {"Content-Type": "application/json"}

    # Try candidates in order
    candidates = []
    # Use provided URL as-is first, assume chat
    candidates.append((u, chat_payload, "chat"))
    # Common roots
    candidates.append((f"{root}/chat/completions", chat_payload, "chat"))
    candidates.append((f"{root}/completions", comp_payload, "completion"))
    candidates.append((f"{root}/chat", chat_payload, "chat"))

    last_error: Optional[Exception] = None
    for url, payload, mode in candidates:
        try:
            resp = requests.post(url, headers=headers, json=payload, timeout=timeout)
            if resp.status_code == 404:
                last_error = Exception(f"404 at {url}: {resp.text[:200]}")
                continue
            resp.raise_for_status()
            data = resp.json()
            if mode == "chat":
                content = data["choices"][0]["message"]["content"]
            else:
                # completion: text field
                content = data["choices"][0].get("text", "")
            if not content:
                raise ValueError(f"Empty content from {url}")
            return content
        except Exception as e:
            last_error = e
            continue
    raise RuntimeError(f"All LLM endpoint attempts failed. Last error: {last_error}")


def main():
    ap = argparse.ArgumentParser(description="Extract algorithm docs and query local LLM for structured JSON.")
    ap.add_argument("--manual", type=Path, default=ROOT/"docs"/"manual-1.10.0.md")
    ap.add_argument("--out-dir", type=Path, default=ROOT/"docs"/"algorithms_llm_review")
    ap.add_argument("--base-url", type=str, default=os.environ.get("LLM_URL", "http://dev.local:1234/v1/chat/completions"))
    ap.add_argument("--model", type=str, default=os.environ.get("LLM_MODEL", "local-model"))
    ap.add_argument("--delay", type=float, default=0.0, help="Delay between requests (seconds)")
    ap.add_argument("--overwrite", action="store_true", help="Overwrite existing JSON outputs")
    ap.add_argument("--only-guid", type=str, default=None, help="Process a single GUID (4 chars)")
    ap.add_argument("--dry-run", action="store_true", help="Do not call LLM; only write fragments and metadata")
    args = ap.parse_args()

    algos = find_algorithms(args.manual)
    if args.only_guid:
        want = normalize_guid(args.only_guid)
        algos = [a for a in algos if a.guid == want]
        if not algos:
            print(f"No algorithm with guid '{want}' found in manual.")
            sys.exit(1)

    out_dir = args.out_dir
    frag_dir = out_dir/"fragments"
    raw_dir = out_dir/"raw"
    out_dir.mkdir(parents=True, exist_ok=True)
    frag_dir.mkdir(parents=True, exist_ok=True)
    raw_dir.mkdir(parents=True, exist_ok=True)

    schema = default_schema()
    processed = 0
    for algo in algos:
        out_file = out_dir/f"{algo.guid}.json"
        if out_file.exists() and not args.overwrite:
            print(f"[skip] {algo.guid} exists")
            continue

        # Always write the fragment for review
        (frag_dir/f"{algo.guid}.md").write_text(
            f"# {algo.name}\n\nLines {algo.start_line}-{algo.end_line} in {args.manual.name}\n\n" + algo.fragment,
            encoding="utf-8",
        )

        if args.dry_run:
            print(f"[dry] {algo.guid} fragment written; skipping LLM call")
            continue

        try:
            messages = build_prompt(algo.guid, algo.name, algo.fragment, schema)
            content = call_llm(args.base_url, args.model, messages)
            # Save raw
            (raw_dir/f"{algo.guid}.txt").write_text(content, encoding="utf-8")
            # Extract JSON from content (strip backticks if present)
            c = content.strip()
            if c.startswith("```"):
                # remove optional ```json fences
                c = re.sub(r"^```[a-zA-Z]*\n", "", c)
                c = re.sub(r"\n```$", "", c)
            data = json.loads(c)
            # Minimal validation
            if normalize_guid(data.get("guid", "")) != algo.guid:
                print(f"[warn] GUID mismatch for {algo.guid} → {data.get('guid')}")
            out_file.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
            print(f"[ok] {algo.guid} → {out_file}")
            processed += 1
        except Exception as e:
            print(f"[err] {algo.guid}: {e}")
        if args.delay:
            time.sleep(args.delay)

    print(f"Done. Processed {processed} algorithms. Output: {out_dir}")


if __name__ == "__main__":
    main()
