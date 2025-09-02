#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANUALS = [ROOT/"docs"/"manual-1.10.0.md", ROOT/"docs"/"manual-1.9.0.md"]
ALG_DIR = ROOT/"docs"/"algorithms"

guid_re = re.compile(r"File format guid: ['\u2018\u2019\u2032\u2035]?([a-z0-9 ]{4})['\u2019\u2018\u2032\u2035]?")
header_re = re.compile(r"^##\s+(.*)")

def normalize_guid(g: str) -> str:
    return g.replace(" ", "").lower()

def load_manual_lines():
    for manual in MANUALS:
        if manual.exists():
            with manual.open('r', encoding='utf-8') as f:
                yield manual.name, f.readlines()

def parse_manual():
    # Map guid -> {name, buses: list of {name, min, max, default}}
    result = {}
    for mname, lines in load_manual_lines():
        cur_guid = None
        cur_header = None
        for i, line in enumerate(lines):
            m = header_re.match(line)
            if m:
                cur_header = m.group(1).strip()
            gm = guid_re.search(line)
            if gm:
                cur_guid = normalize_guid(gm.group(1))
                if cur_guid not in result:
                    result[cur_guid] = {"name": cur_header or "", "buses": []}
                continue
            if not cur_guid:
                continue
            # Heuristic: any line with three numbers (min max default) and 'bus' in text -> routing param
            # Example: "Output 1 28 15 The bus to use as output."
            tokens = line.strip()
            if not tokens:
                continue
            # Skip obvious non-table lines
            if 'bus' not in tokens.lower():
                continue
            # Extract leading name and three numbers
            # Name may contain spaces and / characters.
            nm = re.match(r"^([A-Za-z0-9\-\/() .]+?)\s+(-?[0-9.]+)\s+(-?[0-9.]+)\s+(-?[0-9.]+)\b", tokens)
            if not nm:
                continue
            pname = nm.group(1).strip()
            try:
                mn = float(nm.group(2)); mx = float(nm.group(3)); dv = float(nm.group(4))
            except ValueError:
                continue
            # Only accept bounds in 0..28 range typical for buses
            if not (0 <= mn <= 1 and 20 <= mx <= 32):
                # Allow 0..28 or 1..28 like patterns
                if not (0 <= mn <= 4 and 24 <= mx <= 32):
                    continue
            # Store
            entry = {"name": pname, "min": int(mn), "max": int(mx), "default": dv if (dv % 1) else int(dv)}
            found = result[cur_guid]
            # de-dup by name
            if not any(b["name"].lower() == pname.lower() for b in found["buses"]):
                found["buses"].append(entry)
    return result

def ensure_json(guid: str, name_hint: str):
    path = ALG_DIR/f"{guid}.json"
    if path.exists():
        with path.open('r', encoding='utf-8') as f:
            try:
                data = json.load(f)
            except Exception:
                data = {}
    else:
        data = {
            "guid": guid,
            "name": name_hint or guid,
            "categories": [],
            "description": "",
            "specifications": [],
            "parameters": [],
            "features": [],
            "input_ports": [],
            "output_ports": []
        }
    # normalize required keys
    for k in ["parameters","input_ports","output_ports"]:
        if k not in data or not isinstance(data[k], list):
            data[k] = []
    if "guid" not in data:
        data["guid"] = guid
    if not data.get("name") and name_hint:
        data["name"] = name_hint
    return path, data

def upsert_param(params, p):
    for q in params:
        if q.get("name","" ).lower() == p["name"].lower():
            # update routing details but don’t clobber descriptions
            q["unit"] = "bus"
            q["min"] = p["min"]
            q["max"] = p["max"]
            q["default"] = p["default"]
            q["scope"] = q.get("scope") or "routing"
            return
    params.append({
        "name": p["name"],
        "unit": "bus",
        "min": p["min"],
        "max": p["max"],
        "default": p["default"],
        "scope": "routing",
        "description": ""
    })

def ensure_port(lst, name, kind):
    # kind: 'input' or 'output'
    for i, e in enumerate(list(lst)):
        if isinstance(e, str):
            e2 = {"name": e}
            lst[i] = e2
            e = e2
        if (e.get("name","" ).lower() == name.lower()) or (e.get("busIdRef","" ).lower() == name.lower()):
            e.setdefault("busIdRef", name)
            return
    lst.append({"name": name, "busIdRef": name})

def classify_io(name: str) -> str:
    n = name.lower()
    if "input" in n:
        return "input"
    if "output" in n or "left/mono" in n or n.startswith("left ") or n.startswith("right "):
        return "output"
    # Default to output for ambiguous names like "Output"
    if "out" in n: return "output"
    if "in" in n: return "input"
    return "output"

def main():
    extracted = parse_manual()
    updated = 0
    created = 0
    for guid, info in extracted.items():
        path, data = ensure_json(guid, info.get("name",""))
        # Upsert routing params
        for p in info.get("buses", []):
            upsert_param(data["parameters"], p)
            kind = classify_io(p["name"]) 
            if kind == "input":
                ensure_port(data["input_ports"], p["name"], kind)
            else:
                ensure_port(data["output_ports"], p["name"], kind)
        # Write back
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open('w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        if path.exists():
            updated += 1
        else:
            created += 1
    print(f"Enriched algorithms: updated {updated}, created {created}")

if __name__ == "__main__":
    main()
