# DANXALIYE reference and implementation

Source: [DANXALIYE App](https://claude.ai/artifact/YXtg4LHL7vwCt3hAN5t1KK#page-dcb81aee8d83), inspected 24 October 2026. This shared design supplied the four visible artboards; the earlier WhatsApp PDF paths could not be accessed.

Name: **DANXALIYE**. Tagline: **Baahidaada, Xalkeeda.** Launch location: **Garowe, Puntland**. Primary language of the new flow: Somali. The legacy professional/account management screens retain some English text.

| Reference screen | Implemented web route | Flutter screen |
| --- | --- | --- |
| 1 · Hoyga | `/` | Hoyga |
| 2 · 16 Adeeg | `/Services` | Adeegyada |
| 3 · Samee Dalab | `/Requests/New?category=ID` | Service request form |
| 4 · La soco Dalabka | `/Requests/Track/ID` | Request tracking |

## Services

| Service | Group |
| --- | --- |
| Gaadiid Dalbo | Gaadiid |
| Bajaaj Dalbo | Gaadiid |
| Koronto-yaqaan | Farsamo |
| Tuubiiste | Guriga |
| Alxanle | Farsamo |
| Rinjiile | Guriga |
| AC & Qaboojiye | Farsamo |
| Nijaar | Guriga |
| Solar | Farsamo |
| Nadaafad | Guriga |
| Mechanic | Farsamo |
| CCTV & Amni | Farsamo |
| Electronics | Farsamo |
| Rarid & Guuritaan | Gaadiid |
| Delivery | Gaadiid |
| Dhirayn & Beer | Guriga |

## Real behavior instead of reference placeholders

The reference uses [LAMBARKA], [QIIMAHA], [MAGACA FARSAMOYAQAANKA], [QIIMEYN], a map mockup and an illustrative 15-minute ETA. The implementation leaves unknown prices unset, shows only the actually assigned professional, and reports actual state-transition timestamps. It does not claim a verified identity, paid invoice, live location or computed arrival time. A public support phone, professional verification process, payment gateway and maps/ETA provider still require configuration/implementation.

Photos are private to the customer, assigned professional and administrators. They are stored outside the static file root. PNG/JPEG signature and size validation is implemented; full image decoding, malware scanning and scalable object storage remain production work.

The original high-quality logo PDF is still inaccessible. `wwwroot/brand/danxaliye.svg` and `scripts/prepare-danxaliye-assets.py` provide an interim wordmark and DX house icon, not a claimed reproduction of that logo. Original Dalbo artwork remains archived under branding for provenance, and is not used by the new screens or native launchers.

Internal namespaces, database identity, package/bundle IDs and demo email addresses remain stable to preserve existing data/installations. The GitHub repository remains scxabeeb/Dalbo as previously requested.
