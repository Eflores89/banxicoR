bmx_scalar_text <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x)
}

bmx_object <- function(x) {
  is.list(x) && !is.null(names(x)) && all(nzchar(names(x))) &&
    !anyDuplicated(names(x))
}

bmx_records <- function(records) {
  if (!is.list(records) || !is.null(names(records))) {
    bmx_abort("Response series must be an array.", "response")
  }
  for (record in records) {
    if (!bmx_object(record) || !bmx_scalar_text(record[["idSerie"]]) ||
        (!is.null(record[["titulo"]]) && !bmx_scalar_text(record[["titulo"]]))) {
      bmx_abort("Response contains a malformed series.", "response")
    }
  }
  records
}

bmx_empty_data <- function() {
  data.frame(provider = character(), series_id = character(), title = character(),
    period = character(), date = as.Date(character()), value = double(),
    value_raw = character(), stringsAsFactors = FALSE)
}

bmx_parse_data <- function(records) {
  records <- bmx_records(records)
  rows <- list()
  unexpected <- FALSE
  for (record in records) {
    # Omitted/null datos cannot establish that the series genuinely has no data.
    observations <- record[["datos"]]
    if (!"datos" %in% names(record) || !is.list(observations) ||
        !is.null(names(observations))) {
      bmx_abort("Response observations must be an explicit array.", "response")
    }
    for (observation in observations) {
      if (!bmx_object(observation) || !bmx_scalar_text(observation[["fecha"]]) ||
          !bmx_scalar_text(observation[["dato"]])) {
        bmx_abort("Response contains a malformed observation.", "response")
      }
      period <- observation[["fecha"]]
      date <- as.Date(NA_character_)
      if (grepl("^[0-9]{2}/[0-9]{2}/[0-9]{4}$", period)) {
        date <- as.Date(period, format = "%d/%m/%Y")
      }
      if (is.na(date) || !identical(format(date, "%d/%m/%Y"), period)) {
        bmx_abort("Response contains an invalid observation date.", "response")
      }
      raw <- observation[["dato"]]
      numeric_pattern <- "^[+-]?(?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)(?:\\.[0-9]+)?$"
      value <- NA_real_
      if (grepl(numeric_pattern, raw, perl = TRUE)) {
        value <- as.numeric(gsub(",", "", raw, fixed = TRUE))
        if (!is.finite(value)) {
          bmx_abort("Response contains a numeric value outside the supported range.", "response")
        }
      } else if (!raw %in% c("N/E", "N/D", "N/A", "NA", "")) {
        unexpected <- TRUE
      }
      rows[[length(rows) + 1L]] <- data.frame(provider = "banxico",
        series_id = record[["idSerie"]],
        title = if (is.null(record[["titulo"]])) NA_character_ else record[["titulo"]],
        period = period, date = date, value = value, value_raw = raw,
        stringsAsFactors = FALSE)
    }
  }
  if (unexpected) {
    warning("Unexpected observation text retained as an unavailable value.", call. = FALSE)
  }
  if (!length(rows)) {
    return(bmx_empty_data())
  }
  do.call(rbind, rows)
}

bmx_parse_metadata <- function(records) {
  records <- bmx_records(records)
  out <- data.frame(provider = rep("banxico", length(records)),
    series_id = vapply(records, function(x) x[["idSerie"]], ""),
    title = vapply(records, function(x) {
      if (is.null(x[["titulo"]])) NA_character_ else x[["titulo"]]
    }, ""), stringsAsFactors = FALSE)
  fields <- setdiff(unique(unlist(lapply(records, names), use.names = FALSE)),
    c("idSerie", "titulo", "provider", "series_id", "title"))
  for (field in fields) {
    values <- lapply(records, function(record) record[[field]])
    present <- values[!vapply(values, is.null, logical(1))]
    # Only homogeneous scalar atomic fields simplify; nested JSON stays lossless.
    scalar <- length(present) && all(vapply(present, function(x) {
      is.atomic(x) && length(x) == 1L
    }, logical(1))) && length(unique(vapply(present, typeof, ""))) == 1L
    if (scalar) {
      prototype <- present[[1]][NA_integer_]
      out[[field]] <- do.call(c, lapply(values, function(x) {
        if (is.null(x)) prototype else x
      }))
    } else {
      out[[field]] <- I(values)
    }
  }
  out
}
