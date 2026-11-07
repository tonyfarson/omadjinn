# Brief: top-bar icon for "Omadjinn"

Omadjinn is a window-snapping tool for the Omarchy Linux desktop. Its settings open from an icon in the top bar. I need a small **monochrome genie** icon for that bar, in two designs and two colors each (four SVG files).

## The two designs

- **A. Genie on a flying carpet.** A genie sitting cross-legged on a flying carpet, seen from the side. Readable silhouette: a turban or topknot on the head, upright torso, a carpet as a wavy band underneath with a tassel or two at the ends. The carpet should be clearly visible and distinct from the genie.
- **B. Genie bust.** Head, shoulders and chest only, arms crossed in front of the chest. Turban or topknot on the head. A confident, front-facing pose. Cut the figure off at the chest (a small smoke wisp below is optional; leave it out if it hurts readability).

## The four files

| File | Artwork color | Used on |
| --- | --- | --- |
| `genie-carpet-light.svg` | white `#FFFFFF` | dark bars |
| `genie-carpet-dark.svg` | black `#000000` | light bars |
| `genie-bust-light.svg` | white `#FFFFFF` | dark bars |
| `genie-bust-dark.svg` | black `#000000` | light bars |

Same shapes in both colors. Please also give me a 256 px PNG preview of each on a matching background.

## How big it will really be (read from Omarchy's shell source)

- The bar draws a plugin icon so that its **longest side is 12 logical pixels**, centered in a 16 px square slot. On a 1.5x screen that is about 18 device pixels; on a 2x screen, 24.
- **It has to read as a genie at 12 px.** Think of it as a glyph, not an illustration.
- Design on a **square canvas** (for example a 24x24 or 64x64 viewBox) with the artwork touching or nearly touching the edges. The bar scales the visible shape to fit, so extra empty margin only makes the icon smaller.

## Style: match the other bar icons

The existing icons are single-color, solid silhouette or stencil glyphs: a plug, a robot head, a speaker, a battery, Bluetooth, a hand. Medium to heavy weight, rounded corners, simple shapes, detail made with cut-out gaps in a solid shape (negative space), not with thin outlines.

- Flat single color, transparent background. No gradients, shadows, glows or outlines-only drawing.
- **No detail finer than about 1/12 of the icon's height.** In a 24-unit canvas, no stroke or gap thinner than 2 units.
- No text. No tiny jewelry, faces, eyelashes or fingers. A hint of a face is fine if it stays readable; leaving the face blank is better than a muddy one.
- Clean vector shapes, one path or a few, as plain SVG (no embedded raster, no filters, no fonts).
- If a detail does not survive at 12 px, simplify the shape instead of shrinking the detail.

## Check before you send

Show each file at 12, 16 and 24 px, on a dark background (dark navy, `#1a1b26`) for the white versions and on a light background for the black ones. If the design is not clearly a genie at 12 px, send a simpler version.
