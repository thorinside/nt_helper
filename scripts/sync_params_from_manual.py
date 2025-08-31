#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANUALS = [ROOT/"docs"/"manual-1.10.0.md", ROOT/"docs"/"manual-1.9.0.md"]
ALG_DIR = ROOT/"docs"/"algorithms"

guid_re = re.compile(r"File format guid: ['\u2018\u2019\u2032\u2035]?([a-z0-9 ]{4})['\u2019\u2018\u2032\u2035]?")
header_re = re.compile(r"^##\s+(.*)")
sec_re = re.compile(r"^(Parameters|Routing parameters|Gain parameters|Per-channel parameters|Per-expression parameters|Per-band parameters|Per-channel per-band parameters|Globals parameters|Per-sample parameters|Per-switch parameters|Per-voice parameters|Per-send parameters|Per-track parameters)\b", re.I)

def normalize_guid(g: str) -> str:
    return g.replace(" ", "").lower()

def load_manual_lines():
    for manual in MANUALS:
        if manual.exists():
            with manual.open('r', encoding='utf-8') as f:
                yield manual.name, f.readlines()

def tokenize_tables(lines):
    # Yield (name, entries) groups per algorithm
    cur_guid = None
    cur_name = None
    in_code = False
    rows = []
    pending_name_lines = []

    def flush_pending_numbers(line):
        # Try to parse: <name...> <min> <max> <def> [unit/desc...]
        # We accept numbers anywhere after the name cluster.
        m = re.search(r"(-?[0-9.]+)\s+(-?[0-9.]+)\s+(-?[0-9.]+)\b", line)
        if not m:
            return None
        # Determine name as prior accumulated lines + segment before first number
        name_left = line[:m.start()].strip()
        name = (" ".join(pending_name_lines + ([name_left] if name_left else []))).strip()
        if not name:
            return None
        min_v = m.group(1); max_v = m.group(2); def_v = m.group(3)
        rest = line[m.end():].strip()
        # Unit: look for a short token right after numbers that looks like a unit
        unit = None
        # common units
        unit_candidates = ["V","dB","%","Hz","ST","ms","s","kΩ","μF","MIDI channel"]
        for u in unit_candidates:
            if rest.startswith(u):
                unit = u
                rest = rest[len(u):].strip()
                break
        desc = rest
        # Convert numeric fields to int/float
        def to_num(x):
            try:
                f = float(x)
                return int(f) if f.is_integer() else f
            except Exception:
                return x
        entry = {
            "name": name,
            "min": to_num(min_v),
            "max": to_num(max_v),
            "default": to_num(def_v),
        }
        if unit:
            entry["unit"] = unit
        if desc:
            entry["description"] = desc
        return entry

    for mname, raw_lines in load_manual_lines():
        for raw in raw_lines:
            line = raw.rstrip("\n")
            hm = header_re.match(line)
            if hm:
                cur_name = hm.group(1).strip()
            gm = guid_re.search(line)
            if gm:
                if cur_guid and rows:
                    yield cur_guid, cur_name, rows
                cur_guid = normalize_guid(gm.group(1))
                rows = []
                continue
            if line.strip().startswith("```"):
                in_code = not in_code
                # Reset potential multi-line name buffer when toggling in/out
                pending_name_lines = []
                continue
            if not cur_guid:
                continue
            # Only parse inside code fences based on manual format
            if not in_code:
                # track section lines for potential scope (not used here)
                continue
            # Skip table headers or empty
            if not line.strip() or line.strip().lower().startswith("name "):
                pending_name_lines = []
                continue
            # If line has triple numbers -> complete a row
            entry = flush_pending_numbers(line)
            if entry:
                rows.append(entry)
                pending_name_lines = []
            else:
                # Accumulate name fragments (e.g. "Formant" then next line "input")
                if line.strip():
                    pending_name_lines.append(line.strip())
        # flush last
        if cur_guid and rows:
            yield cur_guid, cur_name, rows

def merge_parameters(existing_params, parsed_rows):
    # existing_params is a list; convert to dict keyed by normalized name
    def norm(s):
        return re.sub(r"\s+", " ", s.lower()).strip()
    by_name = {norm(p.get('name','')): p for p in existing_params if isinstance(p, dict)}
    for row in parsed_rows:
        n = norm(row['name'])
        tgt = by_name.get(n)
        # prefer keeping existing description/unit, but update numeric fields
        if tgt:
            # Preserve existing scope/unit/description if present
            if 'min' not in tgt and 'min' in row:
                tgt['min'] = row['min']
            if 'max' not in tgt and 'max' in row:
                tgt['max'] = row['max']
            if 'default' not in tgt and 'default' in row:
                tgt['default'] = row['default']
            if 'unit' not in tgt and 'unit' in row:
                tgt['unit'] = row['unit']
            if 'description' not in tgt and 'description' in row:
                tgt['description'] = row['description']
        else:
            # Create a new parameter entry; default scope is inferred loosely
            scope = 'routing' if 'input' in n or 'output' in n else None
            entry = {"name": row['name']}
            if 'unit' in row: entry['unit'] = row['unit']
            if 'min' in row: entry['min'] = row['min']
            if 'max' in row: entry['max'] = row['max']
            if 'default' in row: entry['default'] = row['default']
            if 'description' in row: entry['description'] = row['description']
            if scope: entry['scope'] = scope
            existing_params.append(entry)
    return existing_params

def main():
    # Gather parsed parameter rows from manuals
    parsed = {}
    for guid, name, rows in tokenize_tables(list(load_manual_lines())):
        parsed.setdefault(guid, []).extend(rows)

    # Merge into JSON files
    updated = 0
    for jf in ALG_DIR.glob('*.json'):
        try:
            data = json.loads(jf.read_text(encoding='utf-8'))
        except Exception:
            continue
        guid = normalize_guid(data.get('guid',''))
        if not guid or guid not in parsed:
            continue
        params = data.get('parameters', [])
        if not isinstance(params, list):
            params = []
        new_params = merge_parameters(params, parsed[guid])
        data['parameters'] = new_params
        jf.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')
        updated += 1
    print(f"Synced parameters into {updated} algorithm JSON files from manuals.")

if __name__ == '__main__':
    main()

