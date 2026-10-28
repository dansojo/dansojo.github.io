# 김태호 포트폴리오

Buildless HTML/CSS/JavaScript site hosted at https://dansojo.github.io/.

## Structure

- `index.html`: source-checked Korean resume, visual project case studies, research/publication, PDF dialog.
- `assets/style.css`: dark responsive layout and print styles.
- `assets/viewer.js`: native dialog PDF viewer with direct-link fallback.
- `assets/liquid.js`: WebGL liquid hero, reduced-motion and offscreen/visibility pause.
- `assets/previews/`: previews rendered from supplied project PDFs.
- `assets/documents/`: six original project PDFs and the public ICTC poster. Paper manuscript is not available yet; never label a research portfolio as the paper.
- `tests/`: Node behavioral checks without dependencies.

## Preview

Open `index.html` directly or run `python3 -m http.server 8000` and visit http://localhost:8000.

## Checks

```sh
node --check assets/viewer.js
node --check assets/liquid.js
node tests/viewer.test.cjs
node tests/liquid.test.cjs
```

## Source and publishing

Content follows the 2026-10-28 supplied production handoff. Project PDFs are unchanged originals. ICTC poster comes from `dansojo/ictc2026-missingness-stress-test/docs/assets/ictc_poster_A0_841x1189mm.pdf` (Git blob `293725da0cbf2e1b90a73afcd37f0d7462df8d94`). Phone number and address are omitted from the web resume.

Publish the repository root from `main` with GitHub Pages. `.nojekyll` keeps static assets intact. PDFs and screenshots are portfolio materials and are not implicitly licensed as software.
