# Shared observation interface with inegiR

Agreed against the read-only sibling project document
`inegiR/docs/superpowers/specs/2026-10-14-inegir-design.md`, sections Public
interface and Canonical output, reviewed on 2026-10-14. This comparison describes
the agreed design, not a dependency on an installed inegiR or a live verification.

```r
# Each provider requires its own locally configured token:
banxicoR::banxico_data(series = "SF43718", start_date = "2025-01-01",
                      end_date = "2025-12-31", language = "es")
inegiR::inegi_data(series = "1002000001", start_date = "2025-01-01",
                  end_date = "2025-12-31", language = "es",
                  geography = "00", database = "BIE")
```

Both data functions have the first five arguments `series`, `start_date = NULL`,
`end_date = NULL`, `token` (their provider's getter), `language = "es"`.
INEGI appends `geography = "00"`, `database = "BIE"`.
Both define the first seven columns in this order:

| Column | Type | Meaning |
| --- | --- | --- |
| provider | character | `banxico` or `inegi` |
| series_id | character | Provider's identifier |
| title | character | Title when supplied, otherwise NA |
| period | character | Exact source period text |
| date | Date | Provider-specific validated date |
| value | double | Numeric observation, NA when unavailable |
| value_raw | character | Original observation text |

Mixed frequencies require retaining `period`: Banxico parses explicit API
calendar dates, while INEGI's recognized annual, quarterly and monthly periods
use interval-start dates. INEGI preserves unknown or ambiguous periods with NA
dates, and rejects bounded queries that include undated periods. Do not assume
that a date means equal frequency or identical interval coverage across sources.
Banxico orders dates within requested series; INEGI preserves source row order.

INEGI retains provider-specific geography (including leading zeros), frequency,
unit, unit_multiplier, topic, source, notes, status, database and language fields.
Its bank/database selection is source-specific. Banxico does not manufacture
these fields or geographical coverage. Banxico metadata retains available API
fields, including nested values; it makes no claim of identical metadata coverage.
Both APIs expose separate latest/metadata functions and session token helpers;
Banxico has no equivalent to INEGI's catalog endpoint. The bundled historical
BanxicoCatalog is preserved with upstream provenance, not refreshed from INEGI.
