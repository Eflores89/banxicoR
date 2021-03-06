% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/series.R
\name{series}
\alias{series}
\alias{banxico_series}
\alias{banxico_series2}
\title{Returns data series from BANXICO}
\usage{
banxico_series(series, metadata = FALSE, verbose = FALSE, mask = FALSE)

banxico_series2(series, token, metadata = FALSE, mask = FALSE)
}
\arguments{
\item{series}{Series ID}

\item{metadata}{If TRUE returns list with metadata information}

\item{verbose}{If TRUE prints steps while executing. Not available for banxico_series2}

\item{mask}{if TRUE names data column "value", not the id}
}
\value{
data.frame
}
\description{
Returns data.frame with BANXICO data series. Use banxico_series2 for the new API (Beta mode).
}
\examples{
# Bank of Mexico international reserves
\dontrun{
reserves <- banxico_series("SF110168")
}

}
\author{
Eduardo Flores
}
