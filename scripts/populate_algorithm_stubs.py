#!/usr/bin/env python3
"""
Populate new algorithm JSON stubs in docs/algorithms from the v1.9.0 manual.
"""
import os
import re
import json

MANUAL_MD = os.path.join('docs', 'manual-1.9.0.md')
ALG_DIR = os.path.join('docs', 'algorithms')

def load_manual_sections():
    """Parse the manual markdown into sections keyed by algorithm name."""
    heading_re = re.compile(r'^##\s+(?P<name>.+?)\.+$')
    lines = open(MANUAL_MD, encoding='utf-8').read().splitlines()
    heads = []
    for idx, line in enumerate(lines):
        m = heading_re.match(line)
        if m:
            heads.append((idx, m.group('name').strip()))
    # build sections with start/end indices
    sections = {}
    for i, (start, name) in enumerate(heads):
        end = heads[i+1][0] if i+1 < len(heads) else len(lines)
        sections[name] = lines[start:end]
    return sections

def parse_description(section):
    """Extract the Description block as a single-line string."""
    for i, line in enumerate(section):
        if line.strip() == 'Description':
            j = i + 1
            while j < len(section) and not section[j].strip():
                j += 1
            desc_lines = []
            while j < len(section) and section[j].strip():
                desc_lines.append(section[j].strip())
                j += 1
            desc = ' '.join(desc_lines)
            return re.sub(r'\s+', ' ', desc).strip()
    return ''

def parse_specifications(section):
    """Extract bullet specifications, if any."""
    specs = []
    for i, line in enumerate(section):
        if line.strip().startswith('Specifications:'):
            tail = line.strip()[len('Specifications:'):].strip()
            if not tail or tail == 'None':
                return []
            j = i + 1
            while j < len(section):
                ln = section[j].strip()
                if ln.startswith('●'):
                    txt = ln.lstrip('●').strip()
                    m = re.match(r'(?P<name>.*?),\s*(?P<min>[-]?\d+)-(?P<max>\d+):\s*(?P<desc>.*)', txt)
                    if m:
                        specs.append({
                            'name': m.group('name').strip(),
                            'unit': None,
                            'defaultValue': None,
                            'minValue': int(m.group('min')),
                            'maxValue': int(m.group('max')),
                            'description': m.group('desc').strip(),
                        })
                    else:
                        break
                else:
                    break
                j += 1
            break
    return specs

def find_param_blocks(section):
    """Locate parameter/code-table blocks, returning (title, lines) pairs."""
    blocks = []
    for i, line in enumerate(section):
        st = line.strip()
        if st == 'Name Min Max Default Unit Description':
            title = ''
            for k in range(i-1, -1, -1):
                t = section[k].strip()
                if t and not t.startswith('```') and not t.startswith('**'):
                    title = t
                    break
            rows = []
            j = i + 1
            if j < len(section) and section[j].strip().startswith('```'):
                j += 1
            while j < len(section) and not section[j].strip().startswith('```'):
                if section[j].strip():
                    rows.append(section[j].rstrip())
                j += 1
            blocks.append((title, rows))
        elif st.startswith('**Name Min Max Default Unit Description**'):
            title = ''
            for k in range(i-1, -1, -1):
                t = section[k].strip()
                if t and not t.startswith('**') and not t.startswith('```'):
                    title = t
                    break
            rows = []
            code = False
            j = i + 1
            while j < len(section):
                ln = section[j]
                s2 = ln.strip()
                if s2.startswith('```'):
                    code = not code
                elif not code and not s2:
                    break
                elif not s2.startswith('**'):
                    rows.append(ln.rstrip())
                j += 1
            blocks.append((title, rows))
    return blocks

def split_rows(lines):
    """Split a parameter block's lines into (name, data-lines) rows."""
    rows = []
    name_acc = []
    i = 0
    numpat = re.compile(r'^\s*[-]?\d')
    while i < len(lines):
        ln = lines[i]
        if numpat.match(ln):
            name = ' '.join(name_acc).strip()
            name_acc = []
            # collect data lines
            data = [ln.strip()]
            j = i + 1
            while j < len(lines) and not numpat.match(lines[j]) and lines[j].strip():
                data.append(lines[j].strip())
                j += 1
            rows.append((name, data))
            i = j
        else:
            if ln.strip():
                name_acc.append(ln.strip())
            i += 1
    return rows

def to_number(x):
    return float(x) if '.' in x else int(x)

def parse_parameters(section):
    """Parse all parameter blocks into parameter definitions and port lists."""
    param_defs = []
    inputs = []
    outputs = []
    blocks = find_param_blocks(section)
    for title, blk in blocks:
        tln = title.lower()
        is_port = 'routing parameters' in tln or 'midi' in tln
        # determine scope
        if 'channel' in tln:
            scope = 'channel'
        elif 'step' in tln:
            scope = 'step'
        elif 'expression' in tln:
            scope = 'expression'
        elif 'randomise' in tln:
            scope = 'randomise'
        else:
            scope = 'global'
        for name, data in split_rows(blk):
            parts = data[0].split()
            # locate numeric start
            idx = 0
            while idx < len(parts) and not re.match(r'^-?\d+(?:\.\d+)?$', parts[idx]):
                idx += 1
            if idx + 1 >= len(parts):
                continue
            minv = parts[idx]
            maxv = parts[idx+1]
            default = None
            unit = None
            desc_idx = idx + 2
            if desc_idx < len(parts) and re.match(r'^-?\d+(?:\.\d+)?$', parts[desc_idx]):
                default = parts[desc_idx]
                desc_idx += 1
            if desc_idx < len(parts) and not parts[desc_idx][0].isdigit():
                unit = parts[desc_idx]
                desc_idx += 1
            desc = ' '.join(parts[desc_idx:])
            # append continuation lines
            for cont in data[1:]:
                desc += ' ' + cont
            desc = re.sub(r'\s+', ' ', desc).strip()
            param = {
                'name': name,
                'unit': unit if unit else None,
                'minValue': to_number(minv),
                'maxValue': to_number(maxv),
                'defaultValue': to_number(default) if default is not None else None,
                'description': desc,
                'scope': scope,
            }
            # detect enumValues (0/1 flags)
            if param['minValue'] == 0 and param['maxValue'] == 1 and isinstance(param['defaultValue'], int):
                # leave boolean as numeric flag
                pass
            param_defs.append(param)
            # treat bus parameters as ports
            if param['unit'] == 'bus':
                port = {
                    'id': name.lower().replace(' ', '_').replace('/', '_'),
                    'name': name,
                    'description': desc,
                    'busIdRef': name,
                    'isPerChannel': scope in ('channel', 'step', 'expression', 'randomise'),
                }
                key = 'input' if 'input' in name.lower() else 'output'
                if key == 'input':
                    inputs.append(port)
                else:
                    outputs.append(port)
    return param_defs, inputs, outputs

def main():
    sections = load_manual_sections()
    # process each stub file
    for fname in sorted(os.listdir(ALG_DIR)):
        if not fname.endswith('.json'):
            continue
        path = os.path.join(ALG_DIR, fname)
        with open(path, encoding='utf-8') as f:
            stub = json.load(f)
        # only update empty stubs
        if stub.get('description') or stub.get('parameters'):
            continue
        name = stub.get('name')
        section = sections.get(name)
        if not section:
            print(f"Manual section not found for {name}")
            continue
        # fill fields
        stub['description'] = parse_description(section)
        stub['specifications'] = parse_specifications(section)
        params, inp, outp = parse_parameters(section)
        stub['parameters'] = params
        stub['input_ports'] = inp
        stub['output_ports'] = outp
        # write back
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(stub, f, indent=2)
            f.write('\n')

if __name__ == '__main__':
    main()