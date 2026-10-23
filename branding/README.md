# Historical Dalbo artwork


Original artwork supplied by the project owner. `dalbo-logo.png` and `dalbo-app-icon.png` match the individually supplied files; other variants and service icons were retained from the supplied ZIP.

- Orange: `#FF6A13`
- Navy: `#16202E`
- Web: trimmed transparent logo, favicon and touch icon in `src/LocalPro.Web/wwwroot/brand`.
- Flutter: packaged logo and mark in `mobile/assets/brand`.
- Android: density-specific launcher icons and a safe-zone adaptive icon with navy background.
- iOS: all catalog sizes, composited onto navy to remove alpha for App Store compatibility.

Run `python3 scripts/prepare-brand-assets.py` with Pillow installed to regenerate derived files. The script removes empty padding, resizes, and composites backgrounds; it does not redraw the supplied designs. Native package identifiers and database names are retained for compatibility.

The active product is now DANXALIYE. These originals are archived for provenance. See docs/danxaliye-reference.md for the interim active wordmark and native icon. Do not run the historical prepare-brand-assets.py script to regenerate current launchers.
