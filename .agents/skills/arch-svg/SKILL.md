---
name: arch-svg
description: Draws architecture diagrams (services, stores, messaging, flows and decision points) as SVG files from docs/architecture.md. Use it when asked for the architecture diagram, a component, deployment or service-flow diagram, or to "draw the architecture".
---

# Architecture as SVG

You write the SVG by hand, as code. Do not use Mermaid, PlantUML or any diagram library. It is the sibling of the `erd-svg` skill: same palette, same fonts.

## Steps

1. Read `docs/architecture.md`. It is the only source: diagrams, zones, nodes and connections come from it. Do not add or remove anything.
2. Read `references/style.md`. It has the measurements, colors, node types and line types.
3. Read `assets/example.svg`. It is a finished diagram: yours must look the same.
4. For each diagram, place every node on the grid so connected nodes are neighbors and every zone is a rectangle that does not overlap another.
5. Compute the position of every node, zone, line and label with the measurements in `references/style.md` before writing.
6. Write each diagram to `docs/diagrams/<name>.svg`.
7. Check: every node and every connection of each diagram is in its SVG, with its line type, its label and, if it has one, its step number; no line crosses a node or a text.

## Format of `docs/architecture.md`

The file can hold several diagrams. Each one is a section:

```markdown
## Diagram: <name>

Title: …
Subtitle: …

### Zones
| id | label | columns | rows |
### Nodes
| id | name | technology | type (APP/API/DB/BUS/EXT) | column | row |
### Connections
| from | to | label | type (sync/async/contingency) | step |
```

If a node has no column and row, you choose its place (step 4).

## Rules

- All text in the SVG is in English.
- One diagram per kind of flow. If a single diagram needs detours that make it hard to read, split it (for example "decision path" vs "background flows") instead of cramming it.
- SVG text does not wrap: one line per `<text>`.
- Fixed light background. No dark mode, no images and no external links. Arrowheads are `<marker>`s inside the same SVG.
- Node names exactly as in `docs/architecture.md`. A node may appear in two bands of the same diagram if it is the same component drawn once per flow; say so in `docs/architecture.md`.
- Lines are orthogonal (horizontal and vertical only) and never cross a node, a text or another line. If they do not fit between neighbors, move the nodes; if they still do not fit, route through a channel (see `references/style.md`).
- The critical path (what the user waits for) is numbered 1, 2, 3…; async flows and contingency paths have no numbers.
- Always include a legend.
- For many elements you may compute coordinates with your own script (no diagram libraries); the result is still SVG written as code. Do not save the script in `docs/`.
