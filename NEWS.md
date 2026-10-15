# banxicoR 0.9.0.9000

* Development contribution replaces IQY HTML scraping with authenticated SIE
  REST API access; configure BANXICO_TOKEN or a session token.
* Adds banxico_data(), banxico_latest(), banxico_metadata() and token helpers.
  Common long-format observations preserve raw periods, raw values and NA rows.
* Retains five legacy exports and positional arguments, Dates/Date column names,
  masking and metadata adapters. Unavailable legacy metadata fields become NA.
* Adds validated inputs, typed errors, bounded batching/retries, offline tests,
  migration guides and shared-interface documentation with inegiR.
* Preserves Eduardo Flores's authorship, CC0 license and historical catalog.
  The development contribution is available in the GitHub fork; it has not
  been released on CRAN or accepted upstream. An active release-maintainer decision remains a
  prerequisite for release; upstream attribution does not imply acceptance.
