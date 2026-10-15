# Contributor preflight (not a CRAN submission)

This is development version 0.9.0.9000, prepared as a GitHub contribution.
Eduardo Flores remains the attributed author and maintainer. No maintainer
approval or CRAN submission is implied. The release maintainer must select an
appropriate release version and approve submission before a CRAN upload.

## Test environment

* Ubuntu 26.04.1 LTS, x86_64-pc-linux-gnu, UTF-8
* R 4.6.1 (2026-06-24)
* Check date: 2026-10-15 UTC (2026-10-14 America/Mexico_City)
* Commands: `R CMD build .`, then `R CMD check --as-cran banxicoR_0.9.0.9000.tar.gz`
* Full check includes PDF manual compilation; no `--no-manual` option.

## Results

0 errors, 0 warnings, 2 NOTEs. PDF manual compilation passed.
The offline test suite passed all 266 assertions (0 failures, warnings or skips).

Remaining NOTEs:

* Incoming feasibility reports that the development version has large
  components (`0.9.0.9000`). It is deliberately retained for the contribution;
  the release maintainer must select the CRAN release version.
* HTML manual validation was skipped because this environment lacks `tidy`.
  PDF manual generation succeeded. HTML validation remains to be run in a
  suitable environment.

## Scope and limitations

* Tests mock the API and run offline. Authenticated live API requests and real
  network retry timing have not been verified; no personal token was supplied.
* Windows, macOS, other R versions, win-builder and R-hub were not checked.
* Reverse dependency checks were not run; no claim about the current CRAN
  reverse dependency set is made.
* CRAN incoming feasibility network checks ran as part of `--as-cran`.
