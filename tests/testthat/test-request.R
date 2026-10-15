bmx_response <- function(series, status = 200L, body = NULL) {
  if (is.null(body)) body <- jsonlite::toJSON(list(bmx = list(series = series)), auto_unbox = TRUE)
  httr2::response(status, headers = list(`content-type` = "application/json"), body = charToRaw(body))
}
bmx_mock <- function(mock, code) httr2::with_mocked_responses(mock, code)

test_that("transport builds authenticated HTTPS requests and orders records", {
  result <- bmx_mock(function(req) {
    # libcurl versions may percent-encode the comma separating series IDs.
    expect_identical(utils::URLdecode(req$url), "https://www.banxico.org.mx/SieAPIRest/service/v1/series/SF1,SF2/datos?locale=en")
    expect_identical(unname(req$headers[["Bmx-Token"]]), "explicit-token")
    expect_identical(unname(req$headers[["Accept"]]), "application/json")
    expect_equal(req$options$timeout_ms, 30000)
    expect_false(req$options$followlocation)
    expect_equal(req$policies$retry_max_tries, 3)
    expect_equal(req$policies$retry_max_wait, 60)
    bmx_response(list(bmx_fixture("SF2"), bmx_fixture("SF1")))
  }, bmx_request(c("SF1", "SF2"), "/datos", "explicit-token", "en"))
  expect_identical(vapply(result, `[[`, "", "idSerie"), c("SF1", "SF2"))
})
test_that("fetch batches at twenty and preserves complete order", {
  for (n in c(1, 20, 21)) {
    calls <- 0L
    ids <- paste0("SF", seq_len(n))
    out <- bmx_mock(function(req) {
      calls <<- calls + 1L
      batch <- strsplit(sub(".*series/([^/?]+).*", "\\1", utils::URLdecode(req$url)), ",", fixed = TRUE)[[1]]
      expect_lte(length(batch), 20)
      bmx_response(lapply(rev(batch), bmx_fixture))
    }, bmx_fetch(ids, "", "token", "es"))
    expect_equal(calls, ceiling(n / 20))
    expect_identical(vapply(out, `[[`, "", "idSerie"), ids)
  }
})
test_that("invalid envelopes and incomplete or errored series are rejected", {
  bodies <- c('{"bmxExtra":{"series":[]}}', '{"bmx":{"seriesExtra":[]}}',
    '{"bmx":{"series":{}}}', '{"bmx":{"error":{"mensaje":"token"}}}',
    '{"bmx":{"series":[{"idSerieExtra":"SF1"}]}}', "not json")
  for (body in bodies) expect_error(bmx_mock(function(req) bmx_response(NULL, body = body),
    bmx_request("SF1", "", "token", "es")), class = "banxico_response_error")
  for (series in list(list(), list(bmx_fixture("SF2")), list(bmx_fixture(), bmx_fixture()),
      list(bmx_fixture(), bmx_fixture("SF2")), list(list(idSerie = "SF1", error = "secret")))) {
    expect_error(bmx_mock(function(req) bmx_response(series),
      bmx_request("SF1", "", "token", "es")), class = "banxico_response_error")
  }
})
test_that("HTTP, redirects and connection errors are safe", {
  secret <- "synthetic-sensitive-token"
  for (status in c(302L, 401L, 403L, 404L)) {
    err <- tryCatch(bmx_mock(function(req) bmx_response(NULL, status, secret),
      bmx_request("SF1", "", secret, "es")), error = identity)
    expect_s3_class(err, if (status %in% c(401, 403)) "banxico_authentication_error" else "banxico_http_error")
    expect_false(grepl(secret, paste(capture.output(dput(err)), collapse = ""), fixed = TRUE))
  }
  err <- tryCatch(bmx_mock(function(req) stop(secret), bmx_request("SF1", "", secret, "es")), error = identity)
  expect_s3_class(err, "banxico_connection_error")
  expect_false(grepl(secret, paste(capture.output(dput(err)), collapse = ""), fixed = TRUE))
})
test_that("retry policy is restricted and Retry-After is bounded", {
  expect_true(bmx_transient(httr2::response(429)))
  expect_true(bmx_transient(httr2::response(503)))
  expect_false(bmx_transient(httr2::response(501)))
  expect_false(bmx_transient(httr2::response(401)))
  expect_equal(bmx_retry_after(httr2::response(429, headers = list(`Retry-After` = "999999"))), 10)
  expect_true(is.na(bmx_retry_after(httr2::response(429))))
})
test_that("invalid inputs fail before the transport and failed batches return nothing", {
  calls <- 0L
  bmx_mock(function(req) { calls <<- calls + 1L; stop("unexpected transport") }, {
    for (token in list("", NA_character_, c("a", "b"), "a b", "a\nb")) {
      expect_error(bmx_request("SF1", "", token, "es"), class = "banxico_authentication_error")
    }
    expect_error(bmx_request(rep("SF1", 21) |> paste0(seq_len(21)), "", "token", "es"), class = "banxico_input_error")
    expect_error(bmx_request("SF1", "//evil.example", "token", "es"), class = "banxico_input_error")
    expect_error(bmx_request("SF1", "", "token", "fr"), class = "banxico_input_error")
  })
  expect_equal(calls, 0)
  bmx_mock(function(req) {
    calls <<- calls + 1L
    if (calls == 2L) return(bmx_response(list()))
    bmx_response(lapply(paste0("SF", 1:20), bmx_fixture))
  }, expect_error(bmx_fetch(paste0("SF", 1:21), "", "token", "es"), class = "banxico_response_error"))
})
test_that("untrusted JSON diagnostics never enter response conditions", {
  secret <- "synthetic-sensitive-token"
  for (body in c(secret, paste0('{"bmx":{"error":"', secret, '"}}'))) {
    err <- tryCatch(bmx_mock(function(req) bmx_response(NULL, body = body),
      bmx_request("SF1", "", secret, "es")), error = identity)
    expect_s3_class(err, "banxico_response_error")
    expect_identical(names(err), c("message", "call"))
    expect_false(grepl(secret, conditionMessage(err), fixed = TRUE))
    expect_false(grepl(secret, rawToChar(serialize(err, NULL, ascii = TRUE)), fixed = TRUE))
  }
})
