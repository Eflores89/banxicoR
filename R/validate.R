bmx_ids <- function(series) {
  if (!is.character(series) || !length(series) || anyNA(series) ||
      any(!grepl("^[A-Za-z0-9]+$", series))) {
    bmx_abort("Series must be nonempty character alphanumeric identifiers.", "input")
  }
  unique(toupper(series))
}

bmx_date <- function(x, name) {
  if (is.null(x)) {
    return(NULL)
  }
  valid <- length(x) == 1L && !anyNA(x)
  if (valid && inherits(x, "Date")) {
    valid <- is.finite(as.numeric(x)) && as.numeric(x) == floor(as.numeric(x))
    if (valid) {
      return(x)
    }
  }
  if (valid && is.character(x) && grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)) {
    date <- as.Date(x, format = "%Y-%m-%d")
    if (!is.na(date) && identical(format(date, "%Y-%m-%d"), x)) {
      return(date)
    }
  }
  bmx_abort(paste0(name, " must be a scalar Date or valid YYYY-MM-DD string."), "input")
}

bmx_date_bounds <- function(start_date, end_date) {
  start_date <- bmx_date(start_date, "start_date")
  end_date <- bmx_date(end_date, "end_date")
  if (!is.null(start_date) && !is.null(end_date) && start_date > end_date) {
    bmx_abort("start_date must not be after end_date.", "input")
  }
  list(start_date = start_date, end_date = end_date)
}

bmx_language <- function(language) {
  if (!is.character(language) || length(language) != 1L ||
      is.na(language) || !language %in% c("es", "en")) {
    bmx_abort("language must be 'es' or 'en'.", "input")
  }
  language
}
