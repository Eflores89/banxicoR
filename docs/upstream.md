# Upstream source provenance

This development contribution is based on [Eflores89/banxicoR](https://github.com/Eflores89/banxicoR) and is available in [jadrk040507/banxicoR](https://github.com/jadrk040507/banxicoR). It has not been accepted upstream or released on CRAN.

- Upstream branch resolved: `master`.
- Immutable commit: `fea5806a205ce49b7cc52ff9a75d85fc67db688a` ([source](https://github.com/Eflores89/banxicoR/tree/fea5806a205ce49b7cc52ff9a75d85fc67db688a)).
- Acquisition date: 2026-10-14 (America/Mexico_City).
- Original author and maintainer: Eduardo Flores, `eduardo@enelmargen.org`, preserved from upstream DESCRIPTION.
- Original license: CC0, preserved from upstream DESCRIPTION. Upstream has no separate LICENSE file at this commit.
- Acquisition: GitHub connector resolved the branch and enumerated the complete recursive tree; all file reads used the immutable commit. No AGENTS.md or other repository agent instructions were present in that tree.
- Every imported file was decoded from the connector's base64 response and verified using the Git blob SHA-1 (`blob <byte length>\0<bytes>`), including the binary catalog. The table records the original hashes before local edits.
- Existing design and plan documents were preserved. The read-only `.git` placeholder in the original workspace was not modified during acquisition. A separate checkout at `/tmp/banxicor-publish` is used to prepare GitHub publication; the original source provenance below remains unchanged.

## Imported files

| Path | Original Git blob SHA-1 |
| --- | --- |
| `.Rbuildignore` | `1f06e6c679fac982cdcd6e5f253860a47ac04af1` |
| `.gitignore` | `5b6a0652566d10360493952aec6d4a4febc77083` |
| `DESCRIPTION` | `17234d556f98ad70bddf4d4306db4ef17cb4576c` |
| `NAMESPACE` | `2903c7445846fe2237b4def349a7ca7dbdba7f89` |
| `R/data.R` | `ae443a163cce6d72cca395d64ac3e2f551943e1e` |
| `R/series.R` | `3b07dbda0fcdc74993636e02969525f6d24c2c6a` |
| `README.md` | `99ab86b7a418914104b244831d1fb44253b2f7f6` |
| `banxicoR.Rproj` | `497f8bfcfb9d13ad61d14d79963641e9aeab41b0` |
| `data/BanxicoCatalog.RData` | `c2d09f714ae7aa15f38fb768b4e2278f0d2810c1` |
| `man/BanxicoCatalog.Rd` | `b3d2425faa4a207b655db664f1073a0e3526f363` |
| `man/compact_banxico_series.Rd` | `681e3a1aeccd7ee2736bf77ba8813e0e96caa96b` |
| `man/helpers.Rd` | `316e764a608d44223060efecbe8b19297feb7315` |
| `man/series.Rd` | `30a1f8dfa4d0436c366ac3d5a12dac880f72dcdf` |

## Local changes in the baseline task

`DESCRIPTION` now declares the already imported `jsonlite` dependency, adds `httr2` for the forthcoming transport, and configures testthat edition 3 via Suggests. `stringr`, the upstream license, author, and maintainer remain intact. Offline characterization tests cover the argument names and the five exported functions. No transport behavior has been changed in this task; live retrieval remains unverified without a user-provided token.
