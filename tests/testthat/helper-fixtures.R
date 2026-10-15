bmx_fixture <- function(id = "SF1", title = "Synthetic", datos = list()) {
  list(idSerie = id, titulo = title, datos = datos)
}

bmx_observation <- function(period = "01/10/2026", value = "1,234.50") {
  list(fecha = period, dato = value)
}
