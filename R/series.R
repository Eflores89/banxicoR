#' Returns data series from BANXICO
#'
#' Returns data.frame with BANXICO data series
#'
#' @param series Series ID
#' @param metadata If TRUE returns list with metadata information
#' @param verbose If TRUE prints steps while executing
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
#' @importFrom rvest read_html
#' @importFrom rvest html_table
#' @export
banxico_series <- function(series, metadata = FALSE, verbose = FALSE){
  # 0. Build data series
  s <- as.character(series)
  s <- paste0("http://www.banxico.org.mx/SieInternet/consultasieiqy?series=",
              series, "&locale=en")
  # Download data
  h <- read_html(x = s)
  d <- html_nodes(x = h,
                  css = "table")
  # to see the frequency
  m <- html_table(x = d[3], # watch out for this!
                  fill = TRUE,
                  header = TRUE,
                  trim = TRUE)
  m <- m[[1]][!is.na(m[[1]])]

  # Meta-data (short)
  frequency <- gsub(pattern = "frequency:",
                    replacement = "",
                    x = as.character(m[grepl(pattern = "frequency",
                       x = m)]), ignore.case = TRUE
                    )
  frequency <- gsub(pattern = " ",
                    replacement = "",
                    x = frequency)
  frequency <- tolower(frequency)
  if(verbose){
    print(frequency)
  }

  # Parse the data and fix the data.frame
  n <- length(d)
  e <- html_table(x = d[n],
                  fill = TRUE, header = TRUE)
  e <- e[[1]] # from list
  names(e) <- gsub(pattern = "FECHA",
                   replacement = "Dates",
                   x = names(e)) # make sure english

  # Now, the formats
  e[, 2] <- gsub(
    pattern = ",",
    replacement = "",
    x = e[, 2])
  e[, 2] <- as.numeric(e[, 2])

  # if mensual...
  if(frequency == "monthly"){
    e[, 1] <- as.Date(x = paste0("1/",e[, 1]),
                      format = "%d/%m/%Y")
  }

  if(metadata){
    # html_text(html_nodes(x = html_nodes(d, "table")[1], css = "tr td font"))
    # return(l)
  }else{
    return(e)
  }
}
