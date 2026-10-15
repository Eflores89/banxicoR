test_that("legacy adapters retain positional arguments, names and missing rows", {
  calls <- character()
  local_mocked_bindings(bmx_fetch = function(ids, suffix, ...) {
    calls <<- c(calls, suffix)
    list(bmx_fixture(ids, "Synthetic title", list(bmx_observation(), bmx_observation("02/10/2026", "N/E"))))
  })
  withr::local_envvar(BANXICO_TOKEN = "synthetic-token")
  x <- banxico_series("SF43718", TRUE, FALSE, TRUE)
  expect_named(x, c("MetaData", "Data"))
  expect_named(x$Data, c("Dates", "Values"))
  expect_equal(nrow(x$Data), 2)
  expect_true(is.na(x$Data$Values[2]))
  expect_named(x$MetaData, c("IndicatorName", "IndicatorId", "Units", "DataType", "Period", "Frequency"))
  expect_identical(x$MetaData$IndicatorName, "Synthetic title")
  expect_true(all(is.na(unlist(x$MetaData[3:6]))))
  expect_identical(calls, c("/datos", ""))
  expect_named(banxico_series2("SF43718", "synthetic-token", TRUE, TRUE), c("Date", "Value", "Name"))
  expect_named(banxico_series("SF43718"), c("Dates", "SF43718"))
  expect_named(banxico_series2("SF43718"), c("Date", "SF43718"))
  expect_message(banxico_series("SF43718", verbose = TRUE), "Downloaded 2 observations")
  expect_named(compact_banxico_series("SF43718"), c("Dates", "SF43718", names(x$MetaData)))
})

test_that("legacy adapters reject multiple IDs and malformed flags before HTTP", {
  local_mocked_bindings(bmx_fetch = function(...) stop("unexpected fetch"))
  for (fn in list(banxico_series, banxico_series2, compact_banxico_series)) {
    expect_error(fn(c("SF1", "SF2"), token = "synthetic-token"), "one series", class = "banxico_input_error")
  }
  expect_error(banxico_series("SF1", metadata = NA, token = "synthetic-token"), class = "banxico_input_error")
  expect_error(banxico_series2("SF1", "synthetic-token", mask = "yes"), class = "banxico_input_error")
})

test_that("empty legacy outputs are typed and compact metadata does not recycle", {
  local_mocked_bindings(bmx_fetch = function(ids, ...) list(bmx_fixture(ids)))
  withr::local_envvar(BANXICO_TOKEN = "synthetic-token")
  x <- banxico_series("SF1", TRUE, mask = TRUE)
  expect_equal(nrow(x$Data), 0)
  expect_s3_class(x$Data$Dates, "Date")
  expect_type(x$Data$Values, "double")
  y <- banxico_series2("SF1", metadata = TRUE, mask = TRUE)
  expect_named(y, c("Date", "Value", "Name"))
  expect_type(y$Name, "character")
  expect_equal(nrow(compact_banxico_series("SF1")), 0)
})
