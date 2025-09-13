#!/usr/bin/env python3
"""
Script to remove non-ASCII Unicode characters from JSON files in docs/algorithms/
Replaces common Unicode characters with ASCII equivalents and removes others.
Creates backups before modifying files.
"""

import json
import os
import sys
import shutil
from pathlib import Path
import unicodedata

def unicode_to_ascii(text):
    """Convert Unicode text to ASCII, replacing common characters."""
    if not isinstance(text, str):
        return text

    # Common replacements for smart quotes and other punctuation
    replacements = {
        '\u2018': "'",  # Left single quotation mark
        '\u2019': "'",  # Right single quotation mark
        '\u201A': "'",  # Single low-9 quotation mark
        '\u201B': "'",  # Single high-reversed-9 quotation mark
        '\u201C': '"',  # Left double quotation mark
        '\u201D': '"',  # Right double quotation mark
        '\u201E': '"',  # Double low-9 quotation mark
        '\u201F': '"',  # Double high-reversed-9 quotation mark
        '\u2032': "'",  # Prime
        '\u2033': '"',  # Double prime
        '\u2013': '-',  # En dash
        '\u2014': '--', # Em dash
        '\u2015': '--', # Horizontal bar
        '\u2026': '...', # Horizontal ellipsis
        '\u00A0': ' ',  # Non-breaking space
        '\u2022': '*',  # Bullet
        '\u2023': '>',  # Triangular bullet
        '\u2024': '.',  # One dot leader
        '\u2025': '..', # Two dot leader
        '\u2027': '-',  # Hyphenation point
        '\u00B0': ' degrees', # Degree sign
        '\u00B1': '+/-', # Plus-minus sign
        '\u00D7': 'x',  # Multiplication sign
        '\u00F7': '/',  # Division sign
        '\u2190': '<-', # Leftwards arrow
        '\u2192': '->', # Rightwards arrow
        '\u2194': '<->', # Left right arrow
        '\u21D0': '<=', # Leftwards double arrow
        '\u21D2': '=>', # Rightwards double arrow
        '\u21D4': '<=>', # Left right double arrow
    }

    # Apply replacements
    for unicode_char, ascii_char in replacements.items():
        text = text.replace(unicode_char, ascii_char)

    # Try to decompose other Unicode characters to ASCII
    # This handles accented characters like é -> e
    text = unicodedata.normalize('NFKD', text)

    # Remove any remaining non-ASCII characters
    text = ''.join(char if ord(char) < 128 else '' for char in text)

    return text

def clean_json_data(data):
    """Recursively clean Unicode from JSON data structure."""
    if isinstance(data, dict):
        return {unicode_to_ascii(k): clean_json_data(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [clean_json_data(item) for item in data]
    elif isinstance(data, str):
        return unicode_to_ascii(data)
    else:
        return data

def process_json_file(filepath, backup=True):
    """Process a single JSON file to remove Unicode characters."""
    filepath = Path(filepath)

    # Create backup if requested
    if backup:
        backup_path = filepath.with_suffix('.json.bak')
        shutil.copy2(filepath, backup_path)
        print(f"Created backup: {backup_path}")

    try:
        # Read the JSON file
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Check if file contains non-ASCII characters
        original_content = json.dumps(data, ensure_ascii=False)
        has_unicode = any(ord(char) >= 128 for char in original_content)

        if not has_unicode:
            print(f"✓ {filepath.name} - No Unicode characters found")
            return False

        # Clean the data
        cleaned_data = clean_json_data(data)

        # Write back to file with ASCII-only content
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(cleaned_data, fp=f, indent=2, ensure_ascii=True)

        print(f"✓ {filepath.name} - Cleaned Unicode characters")
        return True

    except json.JSONDecodeError as e:
        print(f"✗ {filepath.name} - Invalid JSON: {e}")
        return False
    except Exception as e:
        print(f"✗ {filepath.name} - Error: {e}")
        return False

def main():
    # Get the algorithms directory
    script_dir = Path(__file__).parent
    algorithms_dir = script_dir.parent / 'docs' / 'algorithms'

    if not algorithms_dir.exists():
        print(f"Error: Directory not found: {algorithms_dir}")
        sys.exit(1)

    print(f"Processing JSON files in: {algorithms_dir}")
    print("-" * 50)

    # Process all JSON files
    json_files = list(algorithms_dir.glob('*.json'))

    if not json_files:
        print("No JSON files found")
        return

    total_files = len(json_files)
    modified_files = 0

    for json_file in sorted(json_files):
        if process_json_file(json_file, backup=True):
            modified_files += 1

    print("-" * 50)
    print(f"Processed {total_files} files")
    print(f"Modified {modified_files} files")
    print(f"Unchanged {total_files - modified_files} files")

    if modified_files > 0:
        print("\nBackup files created with .bak extension")
        print("To restore original files: rename .json.bak to .json")

if __name__ == "__main__":
    main()