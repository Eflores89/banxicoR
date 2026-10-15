test_that("IDs normalize and deduplicate in first order", {
  expect_identical(bmx_ids(c("sf2", "SF1", "SF2")), c("SF2", "SF1"))
  for (bad in list(character(), NA_character_, c("SF1", NA), "", "SF1/abc",
    "SF1,SF2", " SF1", 123, list("SF1"))) {
    expect_error(bmx_ids(bad), class = "banxico_input_error")
  }
})

test_that("dates require scalar Date or strict valid ISO strings", {
  expect_identical(bmx_date("2026-10-01", "start_date"), as.Date("2026-10-01"))
  expect_identical(bmx_date(as.Date("2026-10-01"), "start_date"), as.Date("2026-10-01"))
  expect_null(bmx_date(NULL, "start_date"))
  for (bad in list("2026-02-30", "2026-2-01", "01/10/2026", NA_character_,
    c("2026-10-01", "2026-10-02"), 123, as.Date(NA))) {
    expect_error(bmx_date(bad, "start_date"), class = "banxico_input_error")
  }
  expect_error(bmx_date_bounds("2026-10-02", "2026-10-01"),
    class = "banxico_input_error")
  expect_identical(bmx_date_bounds(NULL, "2026-10-01"),
    list(start_date = NULL, end_date = as.Date("2026-10-01")))
})

test_that("languages and error categories are explicit", {
  expect_identical(bmx_language("es"), "es")
  expect_identical(bmx_language("en"), "en")
  for (bad in list("fr", "ES", NA_character_, c("es", "en"), NULL, 1)) {
    expect_error(bmx_language(bad), class = "banxico_input_error")
  }
  for (category in c("input", "authentication", "http", "connection", "response")) {
    error <- tryCatch(bmx_abort("Safe message", category), error = identity)
    expect_s3_class(error, paste0("banxico_", category, "_error"))
    expect_s3_class(error, "banxico_error")
    expect_identical(conditionMessage(error), "Safe message")
  }
})
