test_that("tokens validate and configure the session environment", {
  withr::local_envvar(BANXICO_TOKEN = "environment-token")
  expect_identical(banxico_get_token(), "environment-token")
  expect_invisible(banxico_set_token("session-token"))
  expect_identical(banxico_get_token(), "session-token")
  expect_identical(Sys.getenv("BANXICO_TOKEN"), "session-token")
  expect_identical(bmx_token("explicit-token"), "explicit-token")
  for (x in list("", NA_character_, c("a", "b"), "a b", "a\nb", 12)) {
    expect_error(banxico_set_token(x), class = "banxico_authentication_error")
    expect_error(bmx_token(x), class = "banxico_authentication_error")
  }
})
