bmx_token <- function(token = NULL) {
  if (is.null(token)) token <- Sys.getenv("BANXICO_TOKEN", unset = "")
  if (!is.character(token) || length(token) != 1L || is.na(token) ||
      !nzchar(token) || grepl("[[:space:][:cntrl:]]", token)) {
    bmx_abort("A nonempty token without whitespace or control characters is required.", "authentication")
  }
  token
}

#' Configure a Banxico token for this R session
#'
#' @param token A nonempty character token without whitespace or control characters.
#' @return Invisibly returns NULL. The token is stored only in the session environment.
#' @export
banxico_set_token <- function(token) {
  if (is.null(token)) bmx_abort("A token is required.", "authentication")
  token <- bmx_token(token)
  Sys.setenv(BANXICO_TOKEN = token)
  invisible(NULL)
}

#' Retrieve the configured Banxico token
#'
#' Uses the session token configured by [banxico_set_token()], falling back to
#' the BANXICO_TOKEN environment variable. Treat the returned value as secret.
#' @return A validated scalar character token.
#' @export
banxico_get_token <- function() bmx_token()
