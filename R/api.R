#' Retrieve Banxico observations and metadata
#'
#' Uses the authenticated SIE REST API. Obtain a token from Banxico and configure
#' `BANXICO_TOKEN` or use [banxico_set_token()]. Metadata retrieval is explicit.
#' @param series Character vector of alphanumeric series identifiers.
#' @param start_date,end_date Inclusive date bounds as scalar Dates or ISO
#'   YYYY-MM-DD strings. Two bounds use the range endpoint; a single bound
#'   filters full history locally.
#' @param token API token, defaulting to [banxico_get_token()].
#' @param language API locale: `"es"` (default) or `"en"`.
#' @return `banxico_data()` and `banxico_latest()` return a data.frame with
#'   provider, series_id, title, period, date (Date), value (double), and value_raw
#'   columns. Raw API periods and unavailable observations are retained. Rows
#'   follow requested series order and ascending dates within each series.
#'   `banxico_metadata()` returns provider, series_id, title and available raw
#'   API metadata fields; unavailable titles are NA. Empty data is typed.
#' @examples
#' \dontrun{
#' # First configure BANXICO_TOKEN locally with your registered token.
#' x <- banxico_data(c("SF43718", "SF110168"),
#'   start_date = "2025-01-01", end_date = "2025-12-31")
#' banxico_latest("SF43718")
#' banxico_metadata("SF43718")
#' }
#' @export
banxico_data <- function(series, start_date = NULL, end_date = NULL,
                         token = banxico_get_token(), language = "es") {
  ids <- bmx_ids(series)
  bounds <- bmx_date_bounds(start_date, end_date)
  language <- bmx_language(language)
  token <- bmx_token(token)
  suffix <- "/datos"
  if (!is.null(bounds$start_date) && !is.null(bounds$end_date)) {
    suffix <- paste0(suffix, "/", bounds$start_date, "/", bounds$end_date)
  }
  out <- bmx_order_data(bmx_parse_data(bmx_fetch(ids, suffix, token, language)), ids)
  if (!is.null(bounds$start_date)) out <- out[out$date >= bounds$start_date, , drop = FALSE]
  if (!is.null(bounds$end_date)) out <- out[out$date <= bounds$end_date, , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' @rdname banxico_data
#' @export
banxico_latest <- function(series, token = banxico_get_token(), language = "es") {
  ids <- bmx_ids(series)
  language <- bmx_language(language)
  token <- bmx_token(token)
  bmx_order_data(bmx_parse_data(bmx_fetch(ids, "/datos/oportuno", token, language)), ids)
}

#' @rdname banxico_data
#' @export
banxico_metadata <- function(series, token = banxico_get_token(), language = "es") {
  ids <- bmx_ids(series)
  language <- bmx_language(language)
  token <- bmx_token(token)
  out <- bmx_parse_metadata(bmx_fetch(ids, "", token, language))
  out <- out[order(match(out$series_id, ids)), , drop = FALSE]
  rownames(out) <- NULL
  out
}

bmx_order_data <- function(out, ids) {
  out <- out[order(match(out$series_id, ids), out$date), , drop = FALSE]
  rownames(out) <- NULL
  out
}
