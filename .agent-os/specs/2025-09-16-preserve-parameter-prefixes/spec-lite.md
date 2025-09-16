# Spec Summary (Lite)

Fix metadata import to preserve channel prefixes in parameter names (e.g., "1:Input", "2:Input") that are essential for distinguishing multi-channel parameters in the Disting NT module. Currently these prefixes are being incorrectly stripped during import, making it impossible to identify which parameter belongs to which channel.