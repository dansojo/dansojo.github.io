# 김태호 포트폴리오

Buildless HTML/CSS/JavaScript site hosted at https://dansojo.github.io/.

## Structure

- `index.html`: source-checked Korean resume, visual project case studies, research/publication, PDF dialog.
- `assets/style.css`: dark responsive layout and print styles.
- `assets/viewer.js`: native dialog document viewer with direct PDF links, page navigation and zoom.
- `assets/liquid.js`: WebGL liquid hero, manual pause/resume, reduced-motion and offscreen/visibility pause.
- `assets/previews/`: project card images rendered from supplied PDFs.
- `assets/document-pages/` and `assets/document-pages.json`: 30 page previews and extracted source text from seven original PDFs; the manifest records SHA-256 hashes. Images load on demand when navigating the dialog.
- `assets/documents/`: six original project PDFs and the public ICTC poster. Paper manuscript is not available yet; never label a research portfolio as the paper.
- `tests/`: Node behavioral checks without dependencies.

## Preview

Run `python3 -m http.server 8000` and visit http://localhost:8000. Use HTTP so the document preview manifest can load.

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

## Final verification (2026-10-28)

Source TXT manuscripts were compared against the site and one-page resume. Checks passed for source caveats, seven PDF previews, two one-page download links, local references, accessibility ID targets, motion behavior, and PDF A4 page size/content. The generated PDF was rendered and inspected. Real Chromium checks and desktop/mobile screenshots run in GitHub Actions on `qa/browser-review-20261028`. They cover 320–1440px layouts, liquid motion and reduced motion, document page navigation/zoom, dialog focus/close, all original PDFs, all 30 page images and their source hashes, and the one-page resume download. The PDF popup uses rendered pages so its contents display independently of browser PDF plugin support. The resume itself remains a selectable-text, one-page A4 PDF. Review evidence is stored in that branch under `qa-results/`.

Rebuild page previews after changing an original PDF (macOS):

```sh
swift scripts/build-document-previews.swift "$PWD"
```

The full source PDFs remain available through the dialog’s new-tab and download links. Preview zoom is limited by the rendered image resolution.
