# banxicoR 

*An R interface to download data from Banxico's (Bank of Mexico) SIE (Sistema de Información Económica)*

-----
## :construction: Still under development :construction:
-----

### Introduction 

This package is loosely based on the syntax and ideas behind [inegiR](https://github.com/Eflores89/inegiR). 
However, the **Bank of Mexico** does not have an API, so this package basically uses `rvest` to scrape [iqy](https://support.microsoft.com/en-us/kb/157482) calls.
These return html tables and the package does what it can to save it in a convenient `data.frame` or `list` (same as inegiR).

A few caveats:
- I do not control the data definitions at the source (Banxico), so I can't guarantee continuos use. 
- Finding the ID of each series has proven a manual, slow and tedious process because they are not available in the webpage. I'm trying to contact Banxico about getting a catalog, and I'll probably save a dataset in the package, but a lot of indicators will probably be missing. Use at your own risk. 


### Installation

```
library(devtools)
install_github("Eflores89/banxicoR")
```

### Usage

```
# Download the Bank of Mexico international reserves
rsv <- banxico_series(series = "SF110168")

tail(rsv)
#          DATE SF110168
#    2016-01-01 176321.4
#    2016-02-01 178408.8
#    2016-03-01 179708.0
#    2016-04-01 182118.8
#    2016-05-01 179351.0
#    2016-06-01 178829.9
```

### Finding series ID's

To find a specific series ID, I would recommend going to the [SIE webpage](http://www.banxico.org.mx/SieInternet/), navigating towards the desired indicators and then consulting them via HTML. The column name should be the series id (they are usually in this format: "SF60653", with two characters followed by numbers). The package includes a **small and non exhaustive** catalog of series **in spanish**. You can access this by `data("BanxicoCatalog")`.


Then you can find some id's...

```
library(banxicoR)
library(dplyr)
data("BanxicoCatalog")

# To see how many id's by parent subject 
BanxicoCatalog %>% 
  group_by(PARENT) %>% 
  summarise("Id's" = n())

# Source: local data frame [4 x 2]

#                       PARENT     Id's
#                       (chr)     (int)
#  1          Billetes y Monedas    45
#  2 Intermediarios Financierios    37
#  3            Sistemas de Pago    49
#  4              Tipo de Cambio     2

# to bring the specific id of the average duration of 200 peso bills...
BanxicoCatalog %>% 
  filter(PARENT == "Billetes y Monedas") %>% 
  filter(LEVEL_1 == "Duración promedio del billete") %>% 
  filter(LEVEL_2 == "200 pesos") %>% 
  select(ID)

# Source: local data frame [1 x 1]

#      ID
#    (chr)
#1    SM32
```
