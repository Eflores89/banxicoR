# Continuous integration

[R-CMD-check runs](https://github.com/jadrk040507/banxicoR/actions/workflows/R-CMD-check.yaml)
are the source of truth for CI status. A badge alone does not establish that a
particular commit passed: open the run and compare its commit SHA.

## Matrix and pass criteria

Every push to master, pull request targeting master, and manual dispatch runs:

| Runner | R channel |
| --- | --- |
| Ubuntu | release |
| Ubuntu | oldrel-1 |
| Ubuntu | devel |
| Windows | release |
| macOS | release |

All five jobs are required to pass to call the matrix verified. Jobs are
independent, have a 30-minute limit, and do not ignore failures on R devel.
R CMD check builds the source package and runs its installed-package test suite
(currently 266 offline assertions). Errors and warnings fail CI; NOTEs remain
visible in the logs. Runner images and R channels advance over time. Each run
records the actual OS/R and installed dependency versions in session-info.txt.

Checks use --as-cran --no-manual, with CRAN incoming feasibility disabled for
this development contribution. Suggested dependencies are required. CI does
not compile the PDF manual or constitute a CRAN submission check. The local
full-manual check and its limitations are recorded in cran-comments.md.

## Review the evidence

1. Open a run, confirm its commit SHA, and inspect all five job conclusions.
2. Read the check output and the printed testthat summary for each job.
3. Download each job's check-<runner>-<R> artifact (retained for 14 days).
   It contains the build/check output, .Rcheck logs, testthat output and
   session-info.txt, including evidence from successful checks.

To reproduce without remote CRAN admission checks:

```sh
Rscript -e 'install.packages(c("rcmdcheck", "testthat", "withr", "httr2", "jsonlite", "stringr"))'
Rscript -e 'Sys.setenv("_R_CHECK_CRAN_INCOMING_" = "false", "_R_CHECK_FORCE_SUGGESTS_" = "true"); rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning", check_dir = "check")'
```

## Security and live API scope

Workflow permissions are limited to contents: read, checkout does not retain
Git credentials, and all directly used actions are pinned to commit SHAs.
The workflow uses pull_request, never pull_request_target. No custom secrets or
Banxico token are passed to jobs. The test responses are mocks; dependency
installation and R setup still need network access.

Passing these tests does **not** validate Banxico's live API, real credentials,
service availability, or actual retry timing. Authenticated integration tests
remain a separate task requiring an authorized local credential and explicit
execution scope; do not add a personal token to CI logs, source, or artifacts.
