# Internal conditions deliberately contain only caller-supplied safe messages.
bmx_abort <- function(message, category) {
  stop(structure(list(message = message, call = NULL),
    class = c(paste0("banxico_", category, "_error"), "banxico_error",
      "error", "condition")))
}
