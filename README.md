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

## One-page A4 Resume / CV

The header and hero download `assets/documents/taeho-kim-portfolio-a4.pdf`, a one-page A4 portrait resume. The file keeps the existing URL for compatibility. It contains a compact profile, core skills, five selected research/project entries, career, education and certificates. Detailed portfolios and the poster remain on the website.

The concise editorial wording lives in `scripts/build-pdf.swift` and follows the confirmed 2026-10-28 handoff. Update that wording deliberately when facts change; extraction alone does not rewrite the summary.

Build and verify on macOS:

```sh
python3 scripts/export-content.py /private/tmp/resume-export.json
swift scripts/build-pdf.swift /private/tmp/resume-export.json "$PWD" "$PWD/assets/documents/taeho-kim-portfolio-a4.pdf"
swift tests/pdf.test.swift "$PWD"
```

The generator fails on content overflow. The PDF uses white paper, selectable text, and clickable email/GitHub/portfolio links. Phone number and address remain excluded.
