#!/bin/bash
# Copies updated algorithm JSON files from ../nt_docs/output/json/ to docs/algorithms/
# Only copies files that differ from the existing version.

SOURCE_DIR="../nt_docs/output/json"
DEST_DIR="docs/algorithms"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Source directory $SOURCE_DIR not found"
  exit 1
fi

copied=0
skipped=0
new=0

for src in "$SOURCE_DIR"/*.json; do
  filename=$(basename "$src")
  dest="$DEST_DIR/$filename"

  if [ ! -f "$dest" ]; then
    cp "$src" "$dest"
    echo "NEW: $filename"
    ((new++))
  elif ! diff -q "$src" "$dest" > /dev/null 2>&1; then
    cp "$src" "$dest"
    echo "UPDATED: $filename"
    ((copied++))
  else
    ((skipped++))
  fi
done

echo ""
echo "Done: $copied updated, $new new, $skipped unchanged"
