---
name: erd-svg
description: Draws the app's entity-relationship diagram (ERD) as an SVG file from docs/model.md. Use it when asked for the ERD, the database diagram, the entity-relationship diagram, the "MER", or to "draw the data model".
---

# ERD as SVG

You write the SVG by hand, as code. Do not use Mermaid or any diagram library.

## Steps

1. Read `docs/model.md`. It is the only source: do not add or remove tables or attributes.
2. Read `references/style.md`. It has the measurements, the colors and how each relationship is drawn.
3. Read `assets/example.svg`. It is a finished diagram: yours must look the same.
4. Order the tables so that related tables are neighbors.
5. Compute the position of every table with the measurements in `references/style.md` before writing.
6. Write the result to `docs/erd.svg`.
7. Check: every table and every attribute in `docs/model.md` is in the SVG, and every relationship has its line.

## Rules

- All text in the SVG is in English.
- SVG text does not wrap: one line per `<text>`.
- Fixed light background. No dark mode, no images and no external links.
- Table and attribute names exactly as in `docs/model.md`.
- If a relationship does not fit between neighboring tables, reorder the tables. Never draw a line across a table.
- If no order keeps every relationship between neighbors (this happens with odd-length cycles), route an orthogonal line through the bottom channel and the right margin; see "Routed relationship" in `references/style.md`. Explain it in the footer.
- For many tables you may compute coordinates with your own script (no diagram libraries); the result is still SVG written as code. Do not save the script in `docs/`.
