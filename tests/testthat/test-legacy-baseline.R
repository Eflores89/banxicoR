test_that("legacy entry points preserve their positional arguments", {
  expect_identical(names(formals(banxico_series))[1:4],
                   c("series", "metadata", "verbose", "mask"))
  expect_identical(names(formals(banxico_series2))[1:4],
                   c("series", "token", "metadata", "mask"))
  expect_identical(names(formals(compact_banxico_series))[1], "series")
  expect_identical(names(formals(banxico_parsemeta)),
                   c("slist", "lookfor", "exclude"))
  expect_identical(names(formals(banxico_parsetrim)),
                   c("string", "trim_begin"))
  expect_true(all(c("banxico_series", "banxico_series2",
    "compact_banxico_series", "banxico_parsemeta", "banxico_parsetrim") %in%
    getNamespaceExports("banxicoR")))
})

test_that("jsonlite namespace dependency is declared for installation", {
  source_description <- test_path("..", "..", "DESCRIPTION")
  imports_text <- if (file.exists(source_description)) {
    read.dcf(source_description)[1, "Imports"]
  } else {
    packageDescription("banxicoR")$Imports
  }
  imports <- trimws(strsplit(imports_text, ",")[[1]])
  expect_true("jsonlite" %in% imports)
})
