bmx_transient <- function(resp) {
  httr2::resp_status(resp) %in% c(408L, 429L, 500L, 502L, 503L, 504L)
}

bmx_retry_after <- function(resp) {
  value <- httr2::resp_header(resp, "Retry-After")
  if (is.null(value)) return(NA_real_)
  delay <- suppressWarnings(as.numeric(value))
  if (is.na(delay)) {
    date <- suppressWarnings(as.POSIXct(value, format = "%a, %d %b %Y %H:%M:%S GMT", tz = "GMT"))
    delay <- as.numeric(difftime(date, Sys.time(), units = "secs"))
  }
  if (!is.finite(delay)) return(NA_real_)
  max(0, min(10, delay))
}

bmx_has_error <- function(record) {
  any(c("error", "errores", "errorCode", "errorMessage", "codigoError") %in% names(record))
}

bmx_envelope <- function(payload, ids) {
  invalid <- function() bmx_abort("The API returned an invalid or incomplete series response.", "response")
  if (!is.list(payload)) invalid()
  envelope <- payload[["bmx"]]
  if (!is.list(envelope) || bmx_has_error(envelope)) invalid()
  records <- envelope[["series"]]
  if (!is.list(records) || !is.null(names(records))) invalid()
  returned <- vapply(records, function(record) {
    if (!is.list(record) || bmx_has_error(record)) invalid()
    id <- record[["idSerie"]]
    if (!is.character(id) || length(id) != 1L || is.na(id)) invalid()
    id
  }, character(1))
  if (anyDuplicated(returned) || length(returned) != length(ids) ||
      !setequal(returned, ids)) invalid()
  records[match(ids, returned)]
}

bmx_request <- function(ids, suffix = "", token = NULL, language = "es") {
  ids <- bmx_ids(ids)
  if (length(ids) > 20L) bmx_abort("A request accepts at most 20 series.", "input")
  language <- bmx_language(language)
  token <- bmx_token(token)
  if (!is.character(suffix) || length(suffix) != 1L || is.na(suffix) ||
      !grepl("^(/datos(/(oportuno|[0-9]{4}-[0-9]{2}-[0-9]{2}(/[0-9]{4}-[0-9]{2}-[0-9]{2})?))?)?$", suffix)) {
    bmx_abort("Invalid series endpoint suffix.", "input")
  }
  req <- httr2::request(paste0("https://www.banxico.org.mx/SieAPIRest/service/v1/series/",
    paste(ids, collapse = ","), suffix))
  req <- httr2::req_url_query(req, locale = language)
  req <- httr2::req_headers(req, Accept = "application/json", `Bmx-Token` = token)
  req <- httr2::req_timeout(req, 30)
  req <- httr2::req_options(req, followlocation = FALSE)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  req <- httr2::req_retry(req, max_tries = 3, max_seconds = 60,
    retry_on_failure = TRUE, is_transient = bmx_transient,
    after = bmx_retry_after, backoff = function(tries) min(10, 2 ^ (tries - 1)))
  resp <- tryCatch(httr2::req_perform(req), error = function(e) {
    bmx_abort("Unable to connect to the Banxico API.", "connection")
  })
  status <- httr2::resp_status(resp)
  if (status %in% c(401L, 403L)) bmx_abort("Banxico authentication failed.", "authentication")
  if (status < 200L || status >= 300L) bmx_abort("The Banxico API returned an unsuccessful HTTP status.", "http")
  payload <- tryCatch(jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE),
    error = function(e) bmx_abort("The API returned invalid JSON.", "response"))
  bmx_envelope(payload, ids)
}

bmx_fetch <- function(ids, suffix = "", token = NULL, language = "es") {
  ids <- bmx_ids(ids)
  token <- bmx_token(token)
  language <- bmx_language(language)
  batches <- split(ids, ceiling(seq_along(ids) / 20L))
  unname(do.call(c, lapply(batches, bmx_request, suffix = suffix,
    token = token, language = language)))
}
