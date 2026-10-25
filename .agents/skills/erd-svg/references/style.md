# ERD style

## Canvas

- `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 WIDTH HEIGHT" role="img">`, with `<title>` and `<desc>`.
- Background: `<rect width="WIDTH" height="HEIGHT" rx="16" fill="#FBFBFD"/>`.
- Title at x=32, y=44, 20 px, bold, color `#161A26`. Subtitle at x=32, y=66, 13 px, color `#79809A`.
- Text font: `ui-sans-serif, -apple-system, 'Segoe UI', Roboto, Arial, sans-serif`.
- Table and attribute font: `ui-monospace, Menlo, Consolas, monospace`, 13 px, color `#161A26`.

## Grid

- COLS columns (4 by default). Column i (the first is 0) has x = 32 + 240 × i; every table is 176 wide. WIDTH = 240 × COLS (960 with four columns).
- The diagram should be **wider than tall**. With more than about eight tables, pick the number of columns (5–7) and the rows that give the lowest HEIGHT while every relationship stays between neighbors; put tall tables in the same row when you can. Cells may stay empty.
- The first row of tables starts at y=88.
- With more than four tables, the next row starts 64 px below the tallest table of the previous row.
- HEIGHT = where the last row ends + 48.

## A table

For a table at (X, Y) with N attributes:

- Height = 40 + 28 × N.
- Box: `<rect x="X" y="Y" width="176" height="TABLE_HEIGHT" rx="10" stroke-width="1.5"/>` with its color's fill and border.
- Name: centered at x = X + 88, y = Y + 21, bold, 14 px, in the strong color.
- Line under the name: from (X, Y + 32) to (X + 176, Y + 32), in the border color.
- Attribute number i (the first is 0) is centered at y = Y + 46 + 28 × i, with `dy="0.35em"`, at x = X + 46.
- PK or FK badge, left of the attribute: `<rect x="X+10" y="center-9" width="26" height="18" rx="9"/>` and on top the text `PK` or `FK` in white, 10.5 px, bold, centered at x = X + 23.
  - PK: filled with the table's strong color.
  - FK: filled with `#556074`.

## Colors

One color per table, in this order. With more than four tables they repeat.

- Blue: fill `#EEF1FF`, border `#A9B4F2`, strong `#4453C9`.
- Green: fill `#E3F6F3`, border `#86D3CA`, strong `#0F8478`.
- Amber: fill `#FFF3DC`, border `#F0C572`, strong `#A96C05`.
- Purple: fill `#F4EBFF`, border `#C9A6EE`, strong `#7439B8`.

## Relationships

All lines: `fill="none" stroke="#556074" stroke-width="1.75"`.

Between two neighboring tables in the same row, the line is horizontal, 76 px below the top edge (LY = Y + 76). Let A be the right edge of the left table and B the left edge of the right table (B = A + 64).

- Line: `M A,LY H B`.
- "One" side: a vertical bar 14 px from the table. If "one" is on the left: `M A+14,LY-9 V LY+9`. If on the right: `M B-14,LY-9 V LY+9`.
- "Many" side: a 24 px crow's foot opening toward the table. If "many" is on the right: `M B-24,LY L B,LY-11 M B-24,LY L B,LY M B-24,LY L B,LY+11`. If on the left: `M A+24,LY L A,LY-11 M A+24,LY L A,LY M A+24,LY L A,LY+11`.
- Above the line, 18 px up, a `1` near the one side and an `N` near the many side: 13 px, bold, color `#556074`.

Between a table and the one right below it, the line is vertical through the column center (x = X + 88), from the bottom edge of the upper table to the top edge of the lower one, with the bar and the crow's foot rotated.

## One to zero-or-one

A bar at both ends (no crow's foot). Label `1` on the mandatory side and `0..1` on the optional one. On a vertical line, a `0..1` label goes at x = column center + 26 so it does not touch the bar. If the "one" side of a 1:N relationship is optional (nullable FK), its label is `0..1` instead of `1`.

## Routed relationship

When no order keeps every relationship between neighbors:

- It leaves the bottom edge of the "one" table through its column center, goes down to 28 px below the lowest table in the diagram, right to x = WIDTH − 8, up to LY of the "many" table (Y + 76) and enters through its right edge. So the "one" table has no table below it, and the "many" table is in the last column.
- Bar of the "one" side 14 px from its table; 24 px crow's foot at the entry.
- HEIGHT grows by 28 px to make room for the channel.

## Footer

One or two lines of text under the tables, 12.5 px, color `#79809A`, explaining how to read the relationships.
