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

## A4 combined PDF

The header and hero provide a direct download of `assets/documents/taeho-kim-portfolio-a4.pdf`. The 9-page A4 portrait document includes all resume/project prose, collapsed role/evaluation notes, screenshots, research poster and clickable source links. It does not append the full original project PDF decks. The unavailable paper manuscript remains explicitly excluded.

To regenerate on macOS without external dependencies:

```sh
python3 scripts/export-content.py /private/tmp/resume-export.json
swift scripts/build-pdf.swift /private/tmp/resume-export.json "$PWD" "$PWD/assets/documents/taeho-kim-portfolio-a4.pdf"
swift tests/pdf.test.swift "$PWD"
```

Rebuild the PDF when website content changes. Generation fails if content overflows its page. The PDF is designed for printing on white paper; the website retains its dark theme.
