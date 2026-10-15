test_that("public observations satisfy the shared provider contract", {
  columns <- c("provider", "series_id", "title", "period", "date", "value", "value_raw")
  for (empty in c(FALSE, TRUE)) {
    local_mocked_bindings(bmx_fetch = function(ids, ...) {
      list(bmx_fixture(ids, "Shared title", if (empty) list() else list(
        bmx_observation("01/10/2026", "1,234.50"),
        bmx_observation("02/10/2026", "N/E"))))
    })
    for (fn in list(banxico_data, banxico_latest)) {
      x <- fn("SF1", token = "synthetic-token")
      expect_identical(names(x), columns)
      expect_identical(vapply(x, typeof, ""), setNames(
        c("character", "character", "character", "character", "double", "double", "character"), columns))
      expect_s3_class(x$date, "Date")
      expect_equal(nrow(x), if (empty) 0L else 2L)
      if (!empty) {
        expect_identical(x$provider, rep("banxico", 2))
        expect_identical(x$period, c("01/10/2026", "02/10/2026"))
        expect_identical(x$value_raw, c("1,234.50", "N/E"))
        expect_identical(x$value, c(1234.5, NA_real_))
      }
    }
  }
})

test_that("all shared error categories inherit the provider base class", {
  for (category in c("input", "authentication", "http", "connection", "response")) {
    condition <- tryCatch(bmx_abort("Synthetic safe message", category), error = identity)
    expect_s3_class(condition, paste0("banxico_", category, "_error"))
    expect_s3_class(condition, "banxico_error")
    expect_s3_class(condition, "error")
  }
})
