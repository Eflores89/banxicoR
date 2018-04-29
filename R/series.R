#' Returns data series from BANXICO
#'
#' Returns data.frame with BANXICO data series. Use banxico_series2 for the new API (Beta mode).
#'
#' @param series Series ID
#' @param metadata If TRUE returns list with metadata information
#' @param verbose If TRUE prints steps while executing. Not available for banxico_series2
#' @param mask if TRUE names data column "value", not the id
#'
#' @return data.frame
#'
#' @author Eduardo Flores
#'
#' @examples
#' # Bank of Mexico international reserves
#' \dontrun{
#' reserves <- banxico_series("SF110168")
#' }
#'
#' @importFrom xml2 read_html
#' @importFrom rvest html_table
#' @importFrom rvest html_nodes
#' @importFrom rvest html_text
#' @importFrom stringr str_trim
#' @importFrom stringr str_to_title
#' @importFrom jsonlite fromJSON
#' @name series
NULL

#' @rdname series
#' @export
banxico_series <- function(series, metadata = FALSE, verbose = FALSE, mask = FALSE){
  # 0. Build data series
  s <- as.character(series)
  s <- paste0("http://www.banxico.org.mx/SieInternet/consultasieiqy?series=",
              series, "&locale=en")
  # Download data
  h <- xml2::read_html(x = s)

  d <- rvest::html_nodes(x = h,
                  css = "table")
  # ---- print update ----
  if(verbose){
    print(paste0("Data series: ", series, " downloaded"))
  }

  # Metadata parse (careful, highly hack-ish)...
  mtd <- stringr::str_trim(
    rvest::html_text(
      rvest::html_nodes(
        rvest::html_nodes(
          rvest::html_nodes(d, "table"),
          "table"),
        "td")))
  mtd_head <- stringr::str_trim(
    rvest::html_text(
      rvest::html_nodes(
        rvest::html_nodes(
          rvest::html_nodes(
            rvest::html_nodes(d, "table"),
            "table"),
          "td"), "a")))

  frequency <- banxicoR::banxico_parsemeta(mtd, "frequency")

  # ---- print update ----
  if(verbose){
    print(paste0("Data series in ", frequency, " frequency"))
  }

  # Parse the data and fix the data.frame
  n <- length(d)
  e <- rvest::html_table(x = d[n], fill = TRUE, header = TRUE)
  e <- e[[1]] # from list
  names(e) <- gsub(pattern = "FECHA",
                   replacement = "Dates",
                   x = names(e)) # make sure english
  names(e) <- gsub(pattern = "DATE",
                   replacement = "Dates",
                   x = names(e)) # make sure proper
  if(mask){
    names(e)[names(e)!="Dates"] <- "Values"
  }
  # ---- print update ----
  if(verbose){
    print(paste0("Parsing data with ", nrow(e), " rows"))
  }

  # Now, the formats
  e[, 2] <- gsub(
    pattern = ",",
    replacement = "",
    x = e[, 2])
  e[, 2] <- as.numeric(e[, 2])

  # Change N/E's to NA's
  e[e == "N/E"] <- NA

  # Change to date formats
  if(frequency == "monthly"){
    e[, 1] <- base::as.Date(x = paste0("1/",e[, 1]), format = "%d/%m/%Y")
  }else{
    if(frequency == "daily"){
      e[, 1] <- base::as.Date(x = e[, 1], format = "%m/%d/%Y")
    }else{
      if(frequency == "annual"){
        e[, 1] <- base::as.Date(x = paste0("01/01/", e[,1]), format = "%d/%m/%Y")
      }else{
        if(frequency == "quarterly"){
          e[,1] <- base::as.Date(unlist(lapply(X = e[,1],
                                               FUN = function(x) {
                                                 as.character(banxicoR::banxico_parsetrim(string = x, trim_begin = TRUE))
                                               })))
        }else{
          e[,1] <- as.character(e[,1])
          warning("Frequency not supported. Saving as character.")
        }
      }
    }
  }

  if(metadata){
    units <- banxicoR::banxico_parsemeta(mtd, "unit", exclude = FALSE)
    datatype <- banxicoR::banxico_parsemeta(mtd, "data type", exclude = FALSE)
    period <- banxicoR::banxico_parsemeta(mtd, "period", exclude = FALSE)
    names <- banxicoR::banxico_parsemeta(mtd_head, series, exclude = TRUE)
    names <- stringr::str_to_title(paste0(names, collapse = " - "))

    l <- list("MetaData" = list("IndicatorName" = names,
                                "IndicatorId" = series,
                                "Units" = units,
                                "DataType" = datatype,
                                "Period" = period,
                                "Frequency" = frequency),
              "Data" = as.data.frame(e))
    return(l)
  }else{
    return(as.data.frame(e))
  }
}
#' @rdname series
#' @export
banxico_series2 <- function(series, token, metadata = FALSE, mask = FALSE){
  p <- paste0("https://www.banxico.org.mx/SieAPIRest/service/v1/series/", series,"/datos?token=",token)
  s <- fromJSON(p, flatten = T)
  title <- as.character(s$bmx$series$titulo)
  d <- as.data.frame(s$bmx$series$datos)
  
  
  # cut out no numbers
  d <- d[!grepl(pattern = "N/E", x = d$dato, ignore.case = T), ]
  
  # clean numbers ... 
  d$dato <- gsub(pattern = ",", replacement = "", x = d$dato)
  d$dato <- as.numeric(d$dato)
  
  # change names 
  names(d)[names(d) == "fecha"] <- "Date"
  names(d)[names(d) == "dato"] <- "Value"
  
  if(metadata){
    d$Name <- title
  }
  if(!mask){
    names(d)[names(d)=="Value"] <- as.character(series)
  }
  return(d)
}
#' Helper functions for banxico series
#'
#' See details
#' @details \code{banxico_parsetrim} translates banxico trimesters to dates.
#' \code{banxico_parsemeta} extracts metadata from banxico iqy call.
#'
#' @param string x
#' @param trim_begin y
#' @param slist z
#' @param lookfor m
#' @param exclude d
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
#' Compacts data and metadata into a data.frame
#'
#' Returns data.frame with metadata and data from \code{banxico_series()} in data.frame form. Each metadata data is replicated in its corresponding column.
#'
#' @param series series ID
#'
#' @author Eduardo Flores
#' @examples
#' \dontrun{
#' df <- compact_banxico_series("SF110168")
#' }
#'
#' @export
compact_banxico_series <- function(series){
  d <- banxicoR::banxico_series(series = series, metadata = TRUE)
  dat <- d$Data
  dat$IndicatorName <- d$MetaData$IndicatorName
  dat$IndicatorId <- d$MetaData$IndicatorId
  dat$Units <- d$MetaData$Units
  dat$DataType <- d$MetaData$DataType
  dat$Period <- d$MetaData$Period
  dat$Frequency <- d$MetaData$Frequency
  return(dat)
}

