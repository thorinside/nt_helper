# Routing Canvas Visual Editor - Lite Summary

A visual drag-and-drop interface for editing routing configurations in Disting NT algorithm presets, transforming complex parameter-based routing into an intuitive physical port canvas experience.

## Key Points
- Visual canvas displays physical hardware ports (12 inputs, 8 outputs) and algorithm ports as connectable nodes
- Port types clearly distinguished (audio, CV, gate, trigger) with visual styling
- Drag-and-drop interaction for creating/modifying connections between ports
- OOP hierarchy abstracts port extraction and parameter updates for different routing types (Normal, Poly, Width algorithms)
- Clean Port/Connection model abstracts away low-level parameter details
- Real-time validation and undo/redo for connection modifications