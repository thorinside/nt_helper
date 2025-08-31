#!/usr/bin/env python3
import json
import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[1]
MANUALS = [ROOT/"docs"/"manual-1.10.0.md", ROOT/"docs"/"manual-1.9.0.md"]
ALG_DIR = ROOT/"docs"/"algorithms"
OUT = ROOT/"docs"/"audit"/"routing_audit.md"

guid_re = re.compile(r"File format guid: ['\u2018\u2019\u2032\u2035]?([a-z0-9 ]{4})['\u2019\u2018\u2032\u2035]?")
header_re = re.compile(r"^##\s+(.*)")

def normalize_guid(g: str) -> str:
    return g.replace(" ", "").lower()

def normalize_name(s: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9/]+", " ", s.lower())).strip()

def load_manual_lines():
    for manual in MANUALS:
        if manual.exists():
            with manual.open('r', encoding='utf-8') as f:
                yield manual.name, f.readlines()

def parse_manual_buses():
    result = {}
    for mname, lines in load_manual_lines():
        cur_guid = None
        cur_name = None
        for i, raw in enumerate(lines):
            line = raw.rstrip("\n")
            m = header_re.match(line)
            if m:
                cur_name = m.group(1).strip()
            gm = guid_re.search(line)
            if gm:
                cur_guid = normalize_guid(gm.group(1))
                result.setdefault(cur_guid, {"name": cur_name or "", "buses": []})
                continue
            if not cur_guid:
                continue
            if 'bus' not in line.lower():
                continue
            nm = re.match(r"^([A-Za-z0-9\-\/() .]+?)\s+(-?[0-9.]+)\s+(-?[0-9.]+)\s+(-?[0-9.]+)\b", line.strip())
            if not nm:
                continue
            pname = nm.group(1).strip()
            try:
                mn = float(nm.group(2)); mx = float(nm.group(3)); dv = float(nm.group(4))
            except ValueError:
                continue
            # keep within 0..28 range typical of bus params
            if not (0 <= mn <= 4 and 24 <= mx <= 32):
                if not (0 <= mn <= 1 and 20 <= mx <= 32):
                    continue
            entry = {"name": pname, "min": int(mn), "max": int(mx), "default": int(dv) if dv.is_integer() else dv}
            if not any(normalize_name(b["name"]) == normalize_name(pname) for b in result[cur_guid]["buses"]):
                result[cur_guid]["buses"].append(entry)
    return result

def load_repo_json():
    by_guid = {}
    for f in ALG_DIR.glob('*.json'):
        try:
            data = json.loads(f.read_text(encoding='utf-8'))
            guid = normalize_guid(data.get('guid',''))
            if guid:
                by_guid[guid] = (f, data)
        except Exception:
            pass
    return by_guid

def get_json_bus_params(data):
    params = data.get('parameters', []) or []
    buses = []
    for p in params:
        if not isinstance(p, dict):
            continue
        if (p.get('unit') == 'bus') or (normalize_name(p.get('name','')).endswith('output') or normalize_name(p.get('name','')).endswith('input')):
            buses.append(p)
    return buses

def get_defaults(p):
    return p.get('default', p.get('defaultValue'))

def audit():
    manual = parse_manual_buses()
    repo = load_repo_json()
    out_lines = []
    out_lines.append('# Routing Audit (manual vs docs/algorithms)\n')
    missing_json = []
    missing_manual = []
    total_ok = total_warn = total_err = 0
    
    # Manuals missing JSON files
    for guid in sorted(manual.keys()):
        if guid not in repo:
            missing_json.append(guid)
    # JSON files not in manuals
    for guid in sorted(repo.keys()):
        if guid not in manual:
            missing_manual.append(guid)

    if missing_json:
        out_lines.append('## Missing JSON for GUIDs from manual')
        out_lines.append('')
        out_lines.append(', '.join(missing_json))
        out_lines.append('')
    if missing_manual:
        out_lines.append('## JSON present but GUID not found in manual (ok for legacy/custom)')
        out_lines.append('')
        out_lines.append(', '.join(missing_manual))
        out_lines.append('')

    out_lines.append('## Per-GUID Audit')
    out_lines.append('')
    for guid, (path, data) in sorted(repo.items()):
        man = manual.get(guid)
        json_buses = get_json_bus_params(data)
        json_names = {normalize_name(p.get('name','')): p for p in json_buses}
        issues = []
        if not man:
            issues.append(('warn', 'Not found in manual – skipped detailed comparison.'))
        else:
            # Missing routing params per manual
            for mb in man['buses']:
                n = normalize_name(mb['name'])
                jp = json_names.get(n)
                if not jp:
                    issues.append(('err', f"Missing routing parameter '{mb['name']}'"))
                    continue
                # Compare min/max/default
                jm = jp.get('min'); jx = jp.get('max'); jd = get_defaults(jp)
                if jm != mb['min'] or jx != mb['max'] or (jd is not None and jd != mb['default']):
                    issues.append(('warn', f"Mismatch for '{mb['name']}' (manual {mb['min']}-{mb['max']} def {mb['default']}, json {jm}-{jx} def {jd})"))
            # Extra routing params not in manual
            man_names = {normalize_name(b['name']) for b in man['buses']}
            for jn in json_names:
                if jn not in man_names:
                    issues.append(('warn', f"Extra routing parameter in JSON not found in manual: '{json_names[jn].get('name','')}'"))
            # Port checks
            def has_port(port_list, name):
                if not isinstance(port_list, list):
                    return False
                nn = normalize_name(name)
                for e in port_list:
                    if isinstance(e, str):
                        if normalize_name(e) == nn:
                            return True
                    elif normalize_name(e.get('name','')) == nn or normalize_name(e.get('busIdRef','')) == nn:
                        return True
                return False
            for mb in man['buses']:
                kind = 'input' if 'input' in normalize_name(mb['name']) else 'output'
                lst = data.get('input_ports' if kind=='input' else 'output_ports', [])
                if not has_port(lst, mb['name']):
                    issues.append(('warn', f"Missing {kind}_ports entry for '{mb['name']}'"))

        if issues:
            out_lines.append(f"### {guid} – {data.get('name','')} ({path.name})")
            for level, msg in issues:
                if level=='err':
                    total_err += 1
                    out_lines.append(f"- [ERROR] {msg}")
                else:
                    total_warn += 1
                    out_lines.append(f"- [WARN] {msg}")
            out_lines.append('')
        else:
            total_ok += 1

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text('\n'.join(out_lines), encoding='utf-8')
    print(f"Audit complete: ok={total_ok} warn={total_warn} err={total_err} -> {OUT.relative_to(ROOT)}")

if __name__ == '__main__':
    audit()

