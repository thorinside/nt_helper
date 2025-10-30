#!/bin/bash

# Script to remove all debugPrint statements from the Flutter app
# Handles both single-line and multi-line debugPrint calls

set -e

echo "Removing debugPrint statements..."

# Find all Dart files and remove debugPrint statements
find lib test -name "*.dart" -type f | while read -r file; do
    # Use perl for multi-line pattern matching
    # This removes debugPrint(...); including properly balanced parentheses
    # The key is to match balanced parens, not just [^;]*
    perl -i -0777 -pe '
        # Remove debugPrint with proper paren balancing
        s/\s*debugPrint\((?:[^()]*|\((?:[^()]*|\([^()]*\))*\))*\);\s*\n?//g;
    ' "$file"
done

echo "Removed all debugPrint statements."
echo "Running flutter analyze to check for issues..."

flutter analyze

echo "Done."
