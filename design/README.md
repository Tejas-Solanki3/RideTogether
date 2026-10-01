# RideTogether / Design pack

**19 screen artboards + a flow map**, with guided driver and rider journeys, a responsive desktop layout, design tokens, and embedded assets.

## View it immediately

Open `prototype.html`. It is self-contained: fonts, photos, vector art and scripts are embedded. Click the buttons within the screens, or use the screen picker. This is a **static clickable design prototype**, not a second app or a backend simulation. The Flutter live preview is the functional prototype.

## Bring native editable layers into Figma

A local development plugin is included in `figma-plugin/`. No API token, administrator key, or network permission is needed.

1. Open an empty **Figma Design** file in the desktop editor.
2. Choose **Plugins → Development → Import plugin from manifest…**.
3. Select `figma-plugin/manifest.json` and run **RideTogether — Local Design Import**.
4. Click **Create the design pack**. It creates native text layers, shapes, vector illustrations, embedded photos, frames and prototype links.
5. Select the `00-welcome` or `01-find-ride` frame and click **Present**. Use the role choices, Continue, Publish, View ride, Connect and Chat buttons to explore the journey.
6. Save the Figma file normally under your own account. Convert the flat component examples to components / Auto Layout as needed for your coursework or team.

The manifest ID is a local development placeholder, not a published plugin. If your editor asks for your own plugin ID: create **New plugin → Figma Design → With UI**, keep Figma’s generated ID in its manifest, and copy this pack’s `code.js` and `ui.html` into that plugin folder. Add the supplied `documentAccess` and `networkAccess` settings to the generated manifest.

The plugin prefers **Manrope**, then falls back to Inter or Arial if the font is not available. Manrope is included in `../assets/fonts/Manrope.ttf`; install it locally if needed. The plugin uses documented Figma APIs but could not be executed against your Figma account in this workspace. Its import data and JavaScript have been checked locally; editable SVG artboards are included as an independent fallback.

## Alternative: import SVG artboards

Drag any files from `screens/` plus `00-flow.svg` onto the Figma canvas. Vector shapes are editable; depending on Figma’s importer, SVG text may be outlined. Use the native plugin if you need real text layers. SVG files are design assets, **not** screenshots disguised as editable designs.

## Contents

- `00-welcome`: campus sign-in / honest demo entry.
- `01-find-ride`, `01b-find-requests`: route/date search and clear role-specific ride cards.
- `02-post-route`, `03-post-details`, `04-review`, `05-posted`: three guided offer steps and publication.
- `02b-post-request`, `03b-request-details`, `04b-request-review`, `05b-request-posted`: corresponding request flow.
- `06-ride-details`, `06b-request-details`: review an offer or connect using your own matching offer.
- `07-confirmation`, `07b-driver-confirmation`: reservation confirmation on both sides.
- `08-my-matches`, `09-chat`: driver/rider connections and pickup coordination.
- `10-desktop-find`: desktop adaptation.
- `11-design-system`: colours, type, buttons, role indicators and spacing.
- `00-flow.svg`: decision flow with matching justification.
- `tokens.json`: shared visual vocabulary.
- `scenes.json`: native import source, including embedded image data.

## Design rationale

Warm-white surfaces and ink-black actions keep the interface confident without looking busy. Green identifies drivers, while blue identifies riders; icons and words accompany both. Route → Details → Review gives a clear progress cue, and reservation confirmation states exactly what changed. Cards show pickup, destination, departure date, time and seat availability (or seats needed for a request). The custom map is explicitly illustrative, not navigation.

`tools/design_builder.py` rebuilds the SVGs, clickable prototype and plugin UI data after design edits. It uses Python’s standard library and local assets.
