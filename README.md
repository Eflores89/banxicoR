# banxicoR

Development contribution, version 0.9.0.9000, based on Eduardo Flores's CC0
[banxicoR](https://github.com/Eflores89/banxicoR). This version uses Banxico's
SIE REST API. The development fork is [jadrk040507/banxicoR](https://github.com/jadrk040507/banxicoR).
It has not been released on CRAN or accepted upstream. Source attribution
and catalog provenance are recorded in [docs/upstream.md](docs/upstream.md).

## English quick start

Install the development contribution from GitHub:

```r
# install.packages("remotes")
remotes::install_github("jadrk040507/banxicoR")
```

Alternatively, build and install the local source with `R CMD build .` and then
`R CMD INSTALL banxicoR_0.9.0.9000.tar.gz` into your chosen library.
Register for a personal token at the
[Banxico SIE API portal](https://www.banxico.org.mx/SieAPIRest/).
Configure `BANXICO_TOKEN` in your local environment before starting R; alternatively
call `banxico_set_token()` with a securely obtained token for the current session.
Keep credentials out of scripts and version control. The token is sent in the
`Bmx-Token` header, never in the URL. No live request is made by these docs.

```r
library(banxicoR)
# Requires your own locally configured BANXICO_TOKEN:
x <- banxico_data(c("SF43718", "SF110168"),
                  start_date = "2025-01-01", end_date = "2025-12-31")
latest <- banxico_latest("SF43718")
metadata <- banxico_metadata("SF43718")
data("BanxicoCatalog")
head(BanxicoCatalog)
```

The long-format columns are `provider`, `series_id`, `title`, `period`, `date`,
`value`, `value_raw`. `date` is an R Date parsed from the API's calendar date;
`period` preserves its exact text, and `value_raw` preserves the original value.
Unavailable observations remain rows with `NA_real_` values. Metadata requests
are explicit. The preserved Spanish catalog is historical and nonexhaustive;
it is not a current API catalog.

## Migration from IQY scraping

Calls now require a registered API token, including the legacy adapters.
The five legacy exports and their positional arguments remain available.
`banxico_series()` returns `Dates` and an ID-named value column (`Values` with
`mask = TRUE`); `metadata = TRUE` returns `MetaData` and `Data`.
`banxico_series2()` returns `Date` (singular), an ID-named column (`Value` when
masked), and optionally `Name`. `compact_banxico_series()` repeats legacy
metadata per observation. Units, DataType, Period and Frequency unavailable from
the API are `NA`; they are not inferred from the historical scraper.
`banxico_parsetrim()` and `banxico_parsemeta()` remain historical text helpers.

```r
# Requires BANXICO_TOKEN:
legacy <- banxico_series("SF43718", metadata = TRUE, mask = TRUE)
modern <- banxico_data("SF43718")
plot(modern$date, modern$value, type = "l")
```

Requests batch at most 20 IDs, use a 30-second timeout per attempt and at most
three attempts, with capped retry sleeps of 10 seconds. The retry scheduling
deadline is soft; it is not a hard whole-call timeout. Errors inherit
`banxico_error` and a category class: `banxico_input_error`,
`banxico_authentication_error`, `banxico_http_error`, `banxico_connection_error`,
or `banxico_response_error`. Tests run offline; live authentication and timing
remain unverified without a user-provided token.

## Inicio rápido en español

Esta contribución en desarrollo consulta la API REST del SIE y requiere un token personal
registrado en el portal de Banxico. Configure `BANXICO_TOKEN` en su entorno local
o use `banxico_set_token()` durante la sesión. No guarde credenciales en scripts.

```r
library(banxicoR)
# Requiere BANXICO_TOKEN configurado localmente:
datos <- banxico_data("SF43718", start_date = "2025-01-01",
                      end_date = "2025-12-31", language = "es")
reciente <- banxico_latest("SF43718")
ficha <- banxico_metadata("SF43718")
```

`period` y `value_raw` conservan el texto original; `date` es de clase Date y
`value` es numérico. Las observaciones no disponibles se conservan con `NA`.
En las funciones anteriores, `banxico_series()` usa `Dates`, mientras que
`banxico_series2()` usa `Date`. Los campos históricos de metadatos que la API
no proporciona quedan como `NA`. `BanxicoCatalog` conserva el catálogo histórico
en español, sin prometer cobertura completa ni actualización.

See [the shared interface](docs/shared-interface.md) for comparison with inegiR.
Before any release, choose and verify an active release maintainer; the upstream
maintainer attribution is preserved and does not imply their approval.
