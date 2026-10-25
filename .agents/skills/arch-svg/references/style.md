# Architecture diagram style

## Canvas

- `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1056 HEIGHT" role="img">`, with `<title>` and `<desc>`. Wider than the ERD (960) because arrows need wide channels.
- Background: `<rect width="1056" height="HEIGHT" rx="16" fill="#FBFBFD"/>`.
- Title at x=32, y=44, 20 px, bold, color `#161A26`. Subtitle at x=32, y=66, 13 px, color `#79809A`.
- Text font: `ui-sans-serif, -apple-system, 'Segoe UI', Roboto, Arial, sans-serif`.
- Node name font: `ui-monospace, Menlo, Consolas, monospace`.

## Grid

- Four columns. Each node's x is 32, 304, 576 or 848. All are 176 × 72.
- Row 0 starts at y=124. Each next row starts 200 px lower (72 node + 128 gap): 124, 324, 524, 724…
- 96 px between columns (channel middle: X + 224); 128 px between rows (channel middle: Y + 136). Lines run through these channels.
- With few nodes, leave cells empty rather than cramming: whitespace is part of legibility.

## Zones

A zone groups nodes (a repo, a network, one flow…). It is a rectangle around its nodes:

- x = first node's x − 16; width = from that edge to the last node's right edge + 16.
- y = first row's y − 36; height = down to the last row's bottom edge + 16.
- `<rect rx="14" fill="#F3F4F8" stroke="#D5D9E4" stroke-width="1.25" stroke-dasharray="6 5"/>`.
- Label at (x + 16, y + 22): 11.5 px, bold, UPPERCASE, `letter-spacing: .06em`, color `#79809A`.
- Two zones never touch or overlap.
- No line crosses a text. If a line enters the zone from above and would cross its label, move the label to the widest free stretch of the top edge (right-aligned with `text-anchor="end"`, or starting 16 px after the line that bounds it). If it fits nowhere, shorten the label.

## A node

For a node at (X, Y):

- Box: `<rect x="X" y="Y" width="176" height="72" rx="10" stroke-width="1.5"/>` with its type's fill and border.
- Type badge: `<rect x="X+12" y="Y+14" width="34" height="18" rx="9"/>` in the strong color, with the code (`APP`, `API`, `DB`, `BUS`, `EXT`) in white, 10.5 px, bold, centered at x = X + 29, y = Y + 23, `dy="0.35em"`.
- Name: x = X + 54, y = Y + 23, `dy="0.35em"`, monospace 14 px, bold, strong color. At most 14 characters.
- Technology: x = X + 12, y = Y + 54, 12 px, color `#556074`. At most 26 characters.

## Colors by type

- `API` own service or job: blue. Fill `#EEF1FF`, border `#A9B4F2`, strong `#4453C9`.
- `DB` database, cache or file store: green. Fill `#E3F6F3`, border `#86D3CA`, strong `#0F8478`.
- `BUS` messaging / events: amber. Fill `#FFF3DC`, border `#F0C572`, strong `#A96C05`.
- `APP` client and `EXT` external system: purple. Fill `#F4EBFF`, border `#C9A6EE`, strong `#7439B8`.

## Connections

Three line types, all `fill="none"` with an arrowhead at the end (`marker-end`):

- `sync` (a request someone waits for): `stroke="#161A26" stroke-width="1.75"`, solid. It points in the request direction.
- `async` (event or batch load, nobody waits): `stroke="#556074" stroke-width="1.75" stroke-dasharray="6 5"`. It points in the direction data flows.
- `contingency` (degradation path): `stroke="#B42318" stroke-width="1.75" stroke-dasharray="2 4"`.

Arrowhead, one per color, defined in `<defs>`:
`<marker id="ID-a-TYPE" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="COLOR"/></marker>`.

Between two neighboring nodes in the same row: horizontal line at LY = Y + 36, from A (right edge of the left node) to B = A + 96. Label centered at x = A + 48, y = LY − 12, 11.5 px, color `#556074`, at most 14 characters. If the label has a parenthesis (e.g. `/score (breaker)`), the parenthesis goes on a second line below (LY + 18).

Between a node and the one right below it: vertical line at x = X + 88, from the upper node's bottom edge (Y + 72) to the lower node's top edge. Label to the **left** of the line: x = line − 10, `text-anchor="end"`, y = upper bottom edge + 24, `dy="0.35em"`, at most 14 characters. If the left side is taken by another line or label, put it on the right (x = line + 10).

Two connections between the same neighbors (e.g. a `sync` and a `contingency`): offset them 12 px each side of the center.

Fan-out from one node to a column of nodes (e.g. one service calling a cache above-right, a service beside it and a database below-right): the horizontal neighbor gets the straight line; the others leave the node's **top or bottom edge** at x = X + 156, go straight up or down to the target's LY and turn into the target's left side (an L shape). Never leave from the side next to the straight line: its labels sit there.

Return line within a band (e.g. a consumer that calls back the first node of its band): leave the bottom edge at the center, go down to 28 px below the band's nodes (inside the gap between zones), run along and go up into the target's bottom edge at the center. Its label goes above the horizontal segment.

Route below (target in another band with no neighbor): leave the bottom edge, go down to the middle of the row channel, run along it and enter the target through its nearest edge. Leave the node at x = X + 20 or X + 156 rather than the center, so it does not collide with central lines and their labels.

## Steps

On critical-path connections, a circle `r="10"` filled `#161A26` at the middle of the line (or of the longest segment of a routed line, never at a corner), with the number in white, 11 px, bold, centered, `dy="0.35em"`. On horizontal lines the label goes up to LY − 18 to clear the circle; on vertical lines the label moves 16 px away from the line.

## Legend

Below the last zone, 44 px down:

- Three 40 px line samples (sync, async, contingency) with their names, 12 px, color `#556074`, and a step circle with "critical-path step".
- The type badges that appear in the diagram, with their meaning.
- HEIGHT = legend y + 64.
