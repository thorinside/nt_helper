#!/usr/bin/env python3
"""
the JSON schema template to the OpenAI API, and overwrites the stub with the updated JSON.
Fill algorithm stub JSON files in docs/algorithms using the OpenAI API.

This script now also auto-generates new JSON stubs for any algorithms that appear in the manual
(docs/manual-1.9.0.md) but are not yet present under docs/algorithms.

For each JSON stub under docs/algorithms with incomplete fields, this script locates the matching
algorithm section in docs/manual-1.9.0.md, sends the manual section, the current stub JSON, and
the JSON schema template to the OpenAI API, and overwrites the stub with the updated JSON.

Usage:
  # Option 1: export your key in your shell
  #   export OPENAI_API_KEY=your_api_key
  # Option 2: create a `.env` file in the repo root with the key:
  #   OPENAI_API_KEY=your_api_key
  # Then run the script (requires openai and python-dotenv):
  #   pip install openai python-dotenv
  python3 scripts/llm_fill_algorithm_stubs.py
"""

import os
from dotenv import load_dotenv

load_dotenv()
import re
import json
import sys
import openai

MANUAL_MD = os.path.join('docs', 'manual-1.9.0.md')
ALG_DIR = os.path.join('docs', 'algorithms')

# JSON schema template for algorithm documentation entries
JSON_SCHEMA = r"""
Here is the JSON schema for a Disting algorithm documentation entry. The JSON object must include these fields:

{
  "guid": "<string>",                // algorithm GUID
  "name": "<string>",                // algorithm display name
  "categories": ["<string>", ...],   // list of categories; preserve existing categories
  "description": "<string>",         // a brief description of the algorithm
  "specifications": [
    {
      "name": "<string>",
      "unit": "<string|null>",
      "defaultValue": <number|null>,
      "minValue": <number|null>,
      "maxValue": <number|null>,
      "description": "<string>"
    },
    ...
  ],
  "parameters": [
    {
      "name": "<string>",
      "unit": "<string|null>",
      "defaultValue": <number|string|null>,
      "minValue": <number|null>,
      "maxValue": <number|null>,
      "scope": "<string>",            // one of "global","channel","step","expression","randomise"
      "description": "<string>",
      // optional enumValues if applicable:
      "enumValues": ["<string>", ...],
      // optional type if value should be treated as string:
      "type": "string"
    },
    ...
  ],
  "input_ports": [
    {
      "id": "<string>",
      "name": "<string>",
      "description": "<string>",
      "busIdRef": "<string>"
    },
    ...
  ],
  "output_ports": [
    {
      "id": "<string>",
      "name": "<string>",
      "description": "<string>",
      "busIdRef": "<string>"
    },
    ...
  ]
}
"""

def load_manual_sections():
    """Parse the manual markdown into sections keyed by algorithm name."""
    heading_re = re.compile(r'^##\s+(?P<name>.+?)\.+$')
    lines = open(MANUAL_MD, encoding='utf-8').read().splitlines()
    heads = []
    for idx, line in enumerate(lines):
        m = heading_re.match(line)
        if m:
            heads.append((idx, m.group('name').strip()))
    sections = {}
    for i, (start, name) in enumerate(heads):
        end = heads[i+1][0] if i+1 < len(heads) else len(lines)
        sections[name] = "\n".join(lines[start:end])
    return sections

def call_openai_api(prompt: str) -> str:
    # Use the OpenAI Python v1+ client interface (chat.completions) instead of the deprecated ChatCompletion proxy.
    response = openai.chat.completions.create(
        model="gpt-4",
        temperature=0.0,
        messages=[
            {"role": "system", "content": "You are a JSON conversion assistant."},
            {"role": "user", "content": prompt},
        ],
    )
    # Return the content of the assistant's first message choice.
    return response.choices[0].message.content

def fill_stub_with_llm(stub: dict, manual_section: str) -> dict:
    prompt = (
        f"{JSON_SCHEMA}\n\n"
        "Here is the current JSON stub (incomplete or empty fields):\n"
        "```json\n"
        f"{json.dumps(stub, indent=2)}\n"
        "```\n\n"
        "And here is the raw Markdown section for this algorithm from the manual:\n"
        "```markdown\n"
        f"{manual_section}\n"
        "```\n\n"
        "Please output only the complete updated JSON object (no explanation), matching the schema precisely."
    )
    raw = call_openai_api(prompt)
    clean = raw.strip()
    # Strip code fences if present
    if clean.startswith("```"):
        lines = clean.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].startswith("```"):
            lines = lines[:-1]
        clean = "\n".join(lines).strip()
    try:
        return json.loads(clean)
    except json.JSONDecodeError:
        print(f"Error decoding JSON for stub '{stub.get('guid', '?')}' from LLM response:", file=sys.stderr)
        print(clean, file=sys.stderr)
        raise

def main():
    key = os.getenv("OPENAI_API_KEY")
    if not key:
        print("Error: Please set the OPENAI_API_KEY environment variable.", file=sys.stderr)
        sys.exit(1)
    openai.api_key = key

    # Load manual sections (heading name -> markdown text)
    sections = load_manual_sections()

    # Extract manual entries: list of dicts with name, raw GUID, and section text
    manual_entries = []
    for name, text in sections.items():
        m = re.search(r'^File format guid:\s*(.+)$', text, flags=re.MULTILINE)
        if not m:
            print(f"Warning: no GUID found in manual section '{name}'", file=sys.stderr)
            continue
        raw_guid = m.group(1)
        manual_entries.append({'name': name, 'guid': raw_guid, 'text': text})

    # Determine existing algorithm stub filenames (without .json)
    existing_base = {os.path.splitext(f)[0] for f in os.listdir(ALG_DIR) if f.endswith('.json')}

    # Phase 1: generate new stubs for manual entries without existing JSON
    for entry in manual_entries:
        sanitized = entry['guid'].replace(' ', '_')
        if sanitized not in existing_base:
            print(f"Creating new stub {sanitized}.json from manual section '{entry['name']}'")
            stub = {
                'guid': entry['guid'],
                'name': entry['name'],
                'categories': [],
                'description': '',
                'specifications': [],
                'parameters': [],
                'input_ports': [],
                'output_ports': [],
            }
            updated = fill_stub_with_llm(stub, entry['text'])
            path = os.path.join(ALG_DIR, f"{sanitized}.json")
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(updated, f, indent=2)
                f.write('\n')
            existing_base.add(sanitized)

    # Phase 2: update existing stubs with incomplete data
    for fname in sorted(os.listdir(ALG_DIR)):
        if not fname.endswith('.json'):
            continue
        path = os.path.join(ALG_DIR, fname)
        stub = json.load(open(path, encoding='utf-8'))
        # skip stubs that already have description and parameters
        if stub.get('description') and stub.get('parameters'):
            continue
        name = stub.get('name')
        if name not in sections:
            print(f"Skipping {fname}: no manual section found for '{name}'")
            continue
        print(f"Updating {fname} from manual section '{name}'")
        updated = fill_stub_with_llm(stub, sections[name])
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(updated, f, indent=2)
            f.write('\n')

if __name__ == '__main__':
    main()
