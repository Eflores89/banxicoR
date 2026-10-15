test_that("observations preserve raw values, missing rows and periods", {
  records <- list(bmx_fixture(datos = list(
    bmx_observation(), bmx_observation("02/10/2026", "N/E"),
    bmx_observation("03/10/2026", "unexpected")
  )))
  expect_warning(out <- bmx_parse_data(records), "Unexpected")
  expect_identical(out$value, c(1234.5, NA_real_, NA_real_))
  expect_identical(out$value_raw, c("1,234.50", "N/E", "unexpected"))
  expect_identical(out$period, c("01/10/2026", "02/10/2026", "03/10/2026"))
  expect_s3_class(out$date, "Date")
  expect_identical(out$provider, rep("banxico", 3))
  expect_no_warning(bmx_parse_data(list(bmx_fixture(datos = list(
    bmx_observation(value = "N/E")
  )))))
})

test_that("multiple series and absent titles have consistent columns", {
  out <- bmx_parse_data(list(bmx_fixture(datos = list(bmx_observation())),
    list(idSerie = "SF2", datos = list(bmx_observation(value = "-2.5")))))
  expect_identical(out$series_id, c("SF1", "SF2"))
  expect_identical(out$title, c("Synthetic", NA_character_))
  expect_identical(out$value, c(1234.5, -2.5))
})

test_that("genuine empty arrays return the typed canonical schema", {
  for (records in list(list(), list(bmx_fixture()))) {
    out <- bmx_parse_data(records)
    expect_identical(names(out), c("provider", "series_id", "title", "period",
      "date", "value", "value_raw"))
    expect_identical(vapply(out, typeof, ""), c(provider = "character",
      series_id = "character", title = "character", period = "character",
      date = "double", value = "double", value_raw = "character"))
    expect_s3_class(out$date, "Date")
    expect_equal(nrow(out), 0)
  }
})

test_that("malformed observations and containers fail without partial data", {
  bad <- list(NULL, "bad", list(fecha = "01/10/2026"),
    bmx_observation("31/02/2026"), bmx_observation("1/10/2026"),
    bmx_observation(value = 12), bmx_observation(period = c("a", "b")))
  for (observation in bad) {
    expect_error(bmx_parse_data(list(bmx_fixture(datos = list(observation)))),
      class = "banxico_response_error")
  }
  for (container in list(NULL, "bad", list(fecha = "01/10/2026"))) {
    expect_error(bmx_parse_data(list(bmx_fixture(datos = container))),
      class = "banxico_response_error")
  }
  expect_error(bmx_parse_data(list(list(idSerie = "SF1"))),
    class = "banxico_response_error")
})

test_that("invalid numeric grouping stays raw and unavailable", {
  expect_warning(out <- bmx_parse_data(list(bmx_fixture(datos = list(
    bmx_observation(value = "1,23")
  )))), "Unexpected")
  expect_identical(out$value, NA_real_)
  expect_identical(out$value_raw, "1,23")
})

test_that("metadata retains optional and nested fields without invention", {
  nested <- list(unit = "pesos", flags = list("a", "b"))
  out <- bmx_parse_metadata(list(
    c(bmx_fixture(), list(unidad = "Pesos", extra = nested)),
    list(idSerie = "SF2", extra = list(status = TRUE))))
  expect_identical(names(out)[1:3], c("provider", "series_id", "title"))
  expect_identical(out$title, c("Synthetic", NA_character_))
  expect_identical(out$unidad, c("Pesos", NA_character_))
  expect_identical(out$extra[[1]], nested)
  expect_identical(out$extra[[2]], list(status = TRUE))
  expect_equal(nrow(bmx_parse_metadata(list())), 0)
})

test_that("unsimplified JSON retains arrays and rejects object containers", {
  records <- jsonlite::fromJSON('[{"idSerie":"SF1","datos":[{"fecha":"01/10/2026","dato":"3"}]}]',
    simplifyVector = FALSE)
  expect_identical(bmx_parse_data(records)$value, 3)
  for (json in c('[{"idSerie":"SF1","datos":{}}]', '{}')) {
    expect_error(bmx_parse_data(jsonlite::fromJSON(json, simplifyVector = FALSE)),
      class = "banxico_response_error")
  }
})

test_that("JSON field names must match exactly", {
  expect_error(bmx_parse_data(list(bmx_fixture(datos = list(
    list(fechaExtra = "01/10/2026", datoExtra = "7")
  )))), class = "banxico_response_error")
  for (parser in list(bmx_parse_data, bmx_parse_metadata)) {
    expect_error(parser(list(list(idSerieExtra = "SF1", datos = list()))),
      class = "banxico_response_error")
    record <- list(idSerie = "SF1", tituloExtra = "Extra title",
      datos = list(bmx_observation()))
    expect_identical(parser(list(record))$title, NA_character_)
  }
  metadata <- bmx_parse_metadata(list(record))
  expect_identical(metadata$tituloExtra, "Extra title")
})
