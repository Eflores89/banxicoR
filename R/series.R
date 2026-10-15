#' Returns data series from Banxico using the SIE REST API
#'
#' Legacy adapters retain their original column names and argument positions.
#' API access now requires a token: set BANXICO_TOKEN or call
#' [banxico_set_token()]. For multiple series and raw values use [banxico_data()].
#' @param series A single character series identifier.
#' @param metadata Logical; include legacy metadata (or Name in banxico_series2).
#' @param verbose Logical; print a safe observation count after retrieval.
#' @param mask Logical; use Values or Value instead of an ID-named value column.
#' @param token API token, defaulting to [banxico_get_token()].
#' @param start_date,end_date Inclusive scalar Date or ISO YYYY-MM-DD bounds.
#' @param language API locale, either "es" or "en".
#' @return banxico_series returns Dates and an ID-named numeric column (Values
#'   when masked), or a list with MetaData and Data. MetaData contains
#'   IndicatorName, IndicatorId, Units, DataType, Period and Frequency; fields
#'   unavailable from the API are NA. banxico_series2 returns Date and an
#'   ID-named numeric column (Value when masked), plus Name if requested.
#'   Missing observations remain rows with NA values.
#' @author Eduardo Flores
#' @name series
NULL

#' @rdname series
#' @export
banxico_series <- function(series, metadata = FALSE, verbose = FALSE, mask = FALSE,
                           token = banxico_get_token(), start_date = NULL,
                           end_date = NULL, language = "es") {
  id <- bmx_legacy_id(series)
  bmx_flag(metadata, "metadata")
  bmx_flag(verbose, "verbose")
  bmx_flag(mask, "mask")
  out <- banxico_data(id, start_date, end_date, token, language)
  dat <- data.frame(Dates = out$date, Values = out$value)
  if (!mask) names(dat)[2] <- id
  if (verbose) message("Downloaded ", nrow(dat), " observations.")
  if (!metadata) return(dat)
  meta <- banxico_metadata(id, token, language)
  list(MetaData = list(IndicatorName = meta$title[[1]], IndicatorId = id,
    Units = NA_character_, DataType = NA_character_, Period = NA_character_,
    Frequency = NA_character_), Data = dat)
}

#' @rdname series
#' @export
banxico_series2 <- function(series, token = banxico_get_token(), metadata = FALSE,
                            mask = FALSE, start_date = NULL, end_date = NULL,
                            language = "es") {
  id <- bmx_legacy_id(series)
  bmx_flag(metadata, "metadata")
  bmx_flag(mask, "mask")
  out <- banxico_data(id, start_date, end_date, token, language)
  dat <- data.frame(Date = out$date, Value = out$value)
  if (!mask) names(dat)[2] <- id
  if (metadata) dat$Name <- out$title
  dat
}

bmx_legacy_id <- function(series) {
  ids <- bmx_ids(series)
  if (length(series) != 1L) {
    bmx_abort("Legacy adapters require one series; use banxico_data() for multiple series.", "input")
  }
  ids
}

bmx_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    bmx_abort(paste0(name, " must be TRUE or FALSE."), "input")
  }
  invisible(x)
}

#' Helper functions for banxico series
#'
#' Retained helpers for historical quarterly labels and IQY metadata text.
#' These helpers do not contact the API.
#' @details With `trim_begin = FALSE`, the quarterly helper returns the first
#'   day of the quarter's final month, not the quarter's last calendar day.
#'   Unrecognized labels warn and return their nonnumeric text.
#'
#' @param string A single quarterly label such as `"Jan-Mar 2015"`.
#' @param trim_begin Logical; select the quarter's first month when TRUE.
#' @param slist Character vector of legacy metadata lines.
#' @param lookfor Regular expression selecting metadata lines.
#' @param exclude Logical; exclude matching lines when TRUE.
#' @return `banxico_parsetrim()` returns a Date for recognized labels, otherwise
#'   character text. `banxico_parsemeta()` returns lowercase character values
#'   with the text preceding the first colon removed.
#'
#' @importFrom stringr str_extract
#' @importFrom stringr str_trim
#' @examples
#' # trimester
#' string <- "Jan-Mar 2015"
#' trim <- banxico_parsetrim(string)
#' @name helpers
NULL

#' @rdname helpers
#' @export
banxico_parsetrim <- function(string, trim_begin = TRUE){
  y <- stringr::str_extract(string = string, pattern = "[0-9]+")
  s <- gsub(pattern = "[0-9]+",
            replacement = "",
            x = string,
            ignore.case = TRUE)
  s <- stringr::str_trim(s)

  # warning
  if(s %in% c("Jan-Mar", "Apr-Jun", "Jul-Sep", "Oct-Dec")){
    # begin trimming...
    if(trim_begin){
      sf <- ifelse(s == "Jan-Mar" , 1,
                   ifelse(s == "Apr-Jun", 4,
                          ifelse(s == "Jul-Sep", 7,
                                 ifelse(s == "Oct-Dec", 10,
                                        s))))
    }else{
      sf <- ifelse(s == "Jan-Mar" , 3,
                   ifelse(s == "Apr-Jun", 6,
                          ifelse(s == "Jul-Sep", 9,
                                 ifelse(s == "Oct-Dec", 12,
                                        s))))
    }
    r <- as.Date(x = paste0("01/",sf, "/", y), format = "%d/%m/%Y")
  }else{
    r <- as.character(s)
    warning("Trimester in different format, saving as character.")
  }
  return(r)
}
#' @rdname helpers
#' @export
banxico_parsemeta <- function(slist, lookfor, exclude = FALSE){
  if(exclude){
    s <- gsub(pattern = "^.*?: ",
              replacement = "",
              x = tolower(slist[!grepl(pattern = lookfor, x = slist)]))
  }else{
    s <- gsub(pattern = "^.*?: ",
              replacement = "",
              x = tolower(slist[grepl(pattern = lookfor, x = slist)]))
  }
  s <- as.character(s)
  return(s)
}
#' Compact legacy observations and metadata
#'
#' Uses [banxico_series()] with metadata requested explicitly. Configure
#' BANXICO_TOKEN or use [banxico_set_token()] before calling without a token.
#' @param series A single character series identifier.
#' @param token API token, defaulting to [banxico_get_token()].
#' @param start_date,end_date Inclusive scalar Date or ISO YYYY-MM-DD bounds.
#' @param language API locale, either "es" or "en".
#' @return A data.frame with Dates, an ID-named numeric value column, and
#'   IndicatorName, IndicatorId, Units, DataType, Period and Frequency repeated
#'   per observation. Unavailable metadata is NA; empty data has zero rows.
#' @author Eduardo Flores
#' @export
compact_banxico_series <- function(series, token = banxico_get_token(),
                                   start_date = NULL, end_date = NULL,
                                   language = "es") {
  out <- banxico_series(series, metadata = TRUE, token = token,
    start_date = start_date, end_date = end_date, language = language)
  dat <- out$Data
  for (field in names(out$MetaData)) {
    dat[[field]] <- rep(out$MetaData[[field]], nrow(dat))
  }
  dat
}
