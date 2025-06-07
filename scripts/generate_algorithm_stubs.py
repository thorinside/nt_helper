#!/usr/bin/env python3
"""
Generate stub JSON files for new algorithms defined in the manual but missing in docs/algorithms.
"""
import os
import re
import json

# Paths
MANUAL_MD = os.path.join('docs', 'manual-1.9.0.md')
ALG_DIR = os.path.join('docs', 'algorithms')

# Regex patterns
HEADING_RE = re.compile(r'^##\s+(?P<name>.+?)\.+$')
GUID_RE = re.compile(r"File format guid:\s*'(?P<guid>[^']+)'" )

def parse_manual_sections(md_path):
    """Parse manual markdown and return mapping of guid to algorithm name."""
    sections = {}
    current = None
    with open(md_path, encoding='utf-8') as f:
        for line in f:
            m = HEADING_RE.match(line)
            if m:
                current = m.group('name')
                continue
            if current:
                mg = GUID_RE.search(line)
                if mg:
                    code = mg.group('guid')
                    # Handle multiple codes separated by '/'
                    for sub in code.split('/'):
                        sections[sub] = current
                    current = None
    return sections

def find_existing_codes(alg_dir):
    """Return set of existing algorithm GUID codes from JSON filenames."""
    codes = set()
    for fname in os.listdir(alg_dir):
        if not fname.endswith('.json'):
            continue
        code = os.path.splitext(fname)[0]
        codes.add(code)
    return codes

def write_stub(code, name, alg_dir):
    """Write a stub JSON file for the given algorithm code and name."""
    out_path = os.path.join(alg_dir, f'{code}.json')
    stub = {
        'guid': code,
        'name': name,
        'categories': [],
        'description': '',
        'specifications': [],
        'parameters': [],
        'input_ports': [],
        'output_ports': [],
    }
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(stub, f, indent=2)
        f.write('\n')

def main():
    sections = parse_manual_sections(MANUAL_MD)
    existing = find_existing_codes(ALG_DIR)
    # Exclude entries already represented by existing files (including UI Scripts code with whitespace)
    missing = sorted(c for c in set(sections) - existing if ' ' not in c)
    if not missing:
        print('No new algorithms to add.')
        return
    for code in missing:
        name = sections.get(code, '')
        print(f'Creating stub for {code}: {name}')
        write_stub(code, name, ALG_DIR)
    print(f'Created {len(missing)} stub JSON files in {ALG_DIR}')

if __name__ == '__main__':
    main()