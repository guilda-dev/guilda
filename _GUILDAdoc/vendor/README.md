# Third-party software in `_GUILDAdoc/vendor`

The documentation site bundles the files below so that it works offline and from `file://`,
without a CDN. They are redistributed unchanged, under their own licenses; GUILDA's own
license ([`LICENSE`](../../LICENSE), MIT) does not apply to them.

## KaTeX 0.19.1

| | |
|---|---|
| What | Math typesetting library, used by `class.html` and `method.html` to render `$...$` and ```` ```math ```` in help comments |
| Version | 0.19.1 (released 2026-10-23) |
| Source | Official release asset `katex.tar.gz` of <https://github.com/KaTeX/KaTeX/releases/tag/v0.19.1> (SHA-256 `751e29ffb0c5bc184f08692a0aa905ff86a59ced07f635a27e72a7b7bc53036c`) |
| Files | `katex/katex.min.js`, `katex/katex.min.css`, `katex/fonts/*` (all 60 font files of the release) |
| Changes | None. The files are byte-identical to the release. The minified files of the release carry no copyright header. |

### Licenses

| Part | License | Copyright holders | License file |
|---|---|---|---|
| `katex.min.js`, `katex.min.css` | MIT License | Khan Academy and other contributors (2013-2020) | [`katex/LICENSE`](katex/LICENSE), copied verbatim from the `LICENSE` file of the KaTeX repository at tag `v0.19.1` |
| `fonts/*` (font software, Reserved Font Names `KaTeX_AMS`, `KaTeX_Caligraphic`, `KaTeX_Fraktur`, `KaTeX_Main`, `KaTeX_Math`, `KaTeX_SansSerif`, `KaTeX_Script`, `KaTeX_Size1` to `KaTeX_Size4`, `KaTeX_Typewriter`) | SIL Open Font License 1.1 | Design Science, Inc. (2009-2010); Khan Academy (2014-2018) | [`katex/fonts/OFL.txt`](katex/fonts/OFL.txt): the copyright and license statement embedded in the fonts (name records 0 and 13), followed by the OFL 1.1 text copied verbatim from <https://openfontlicense.org/documents/OFL.txt> |
| Font build repository [KaTeX/katex-fonts](https://github.com/KaTeX/katex-fonts) | MIT License | Khan Academy (2018) | [`katex/fonts/LICENSE-katex-fonts`](katex/fonts/LICENSE-katex-fonts), copied verbatim from its `LICENSE` file (commit `56e79c9`) |

The fonts themselves state the OFL 1.1 in their metadata; the MIT file of the font
repository is kept as well, so that every license that may apply travels with the files.

### Why redistribution is allowed

- MIT License: allows use, copy, modification, publishing and distribution, provided the
  copyright notice and permission notice are included (`katex/LICENSE`).
- SIL OFL 1.1: allows the fonts to be bundled and redistributed with any software, provided
  the copyright notice and the license travel with them (`katex/fonts/OFL.txt`) and the
  fonts are not sold by themselves. The Reserved Font Names restrict only modified
  versions; these fonts are unmodified.
- Both apply to this repository, to GitHub, and to the published site on GitHub Pages
  (`GUILDA.publish_doc` copies the whole `_GUILDAdoc` folder, these notices included).

### Updating

Replace the files with those of a newer official release, keep the license files in step
with that release (check the fonts' embedded license again), and update this page.
