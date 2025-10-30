#!/usr/bin/env python3

import os
import re
import subprocess
from pathlib import Path

def remove_debug_prints_from_file(file_path):
    """Remove debugPrint statements from a Dart file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Track if we made changes
    original_content = content

    # Strategy: Find debugPrint( and then count parens to find the matching closing paren
    # Then remove the entire statement including the semicolon

    while True:
        # Find the next debugPrint(
        match = re.search(r'\bdebugPrint\s*\(', content)
        if not match:
            break

        start_pos = match.start()
        paren_start = match.end() - 1  # Position of the opening paren

        # Count parens to find matching close paren
        paren_count = 1
        pos = paren_start + 1

        while pos < len(content) and paren_count > 0:
            if content[pos] == '(':
                paren_count += 1
            elif content[pos] == ')':
                paren_count -= 1
            elif content[pos] == "'" or content[pos] == '"':
                # Skip string literals to avoid counting parens inside them
                quote_char = content[pos]
                pos += 1
                while pos < len(content):
                    if content[pos] == '\\':
                        pos += 2  # Skip escaped character
                        continue
                    if content[pos] == quote_char:
                        break
                    pos += 1
            pos += 1

        if paren_count != 0:
            # Unbalanced parens, skip this occurrence
            content = content[:match.end()] + content[match.end():]
            continue

        # pos is now pointing right after the closing paren
        # Look for the semicolon
        end_pos = pos
        while end_pos < len(content) and content[end_pos] in ' \t':
            end_pos += 1

        if end_pos < len(content) and content[end_pos] == ';':
            end_pos += 1

            # Also consume trailing whitespace/newline if the line becomes empty
            # Find start of line
            line_start = start_pos
            while line_start > 0 and content[line_start - 1] not in '\n\r':
                line_start -= 1

            # Check if everything before debugPrint on this line is whitespace
            prefix = content[line_start:start_pos]
            if prefix.strip() == '':
                # Remove trailing newline too
                while end_pos < len(content) and content[end_pos] in '\n\r':
                    end_pos += 1
                    break  # Only remove one newline
                # Remove from line start to include indentation
                content = content[:line_start] + content[end_pos:]
            else:
                # Just remove the debugPrint statement itself
                content = content[:start_pos] + content[end_pos:]
        else:
            # No semicolon found, just remove what we have
            content = content[:start_pos] + content[end_pos:]

    # Only write if we made changes
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    print("Removing debugPrint statements...")

    # Find all Dart files
    dart_files = []
    for directory in ['lib', 'test']:
        if os.path.exists(directory):
            dart_files.extend(Path(directory).rglob('*.dart'))

    modified_count = 0
    for dart_file in dart_files:
        if remove_debug_prints_from_file(dart_file):
            modified_count += 1

    print(f"Modified {modified_count} files.")
    print("Running flutter analyze to check for issues...")

    result = subprocess.run(['flutter', 'analyze'], capture_output=False)

    if result.returncode == 0:
        print("Done.")
    else:
        print(f"Flutter analyze found issues (exit code: {result.returncode})")

    return result.returncode

if __name__ == '__main__':
    exit(main())
