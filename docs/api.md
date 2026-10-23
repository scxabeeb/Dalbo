# Shared API

Base: `/api`. Public endpoints expose sanitized profile DTOs. Protected application endpoints accept **Identity bearer tokens only**, so browser cookies cannot authorize unsafe API writes. Razor forms use the Identity application cookie and ASP.NET antiforgery validation.

## Identity

ASP.NET Core Identity supplies `/api/auth/register`, `/login`, `/refresh`, and its standard management/recovery endpoints. The prototype uses email/password login. Passwords require at least 10 characters, uppercase, lowercase, digit and symbol. Login lockout is enabled, and Identity endpoints have per-IP rate limiting.

```http
POST /api/auth/login?useCookies=false
Content-Type: application/json

{"email":"customer@localpro.test","password":"YOUR_DEMO_PASSWORD"}
```

Use `Authorization: Bearer ACCESS_TOKEN` for protected routes. Refresh with `/api/auth/refresh`. Flutter persists only the refresh token in secure platform storage and keeps the access token in memory. These are ASP.NET Identity opaque tokens, not JWTs.

Email confirmation/recovery delivery is not configured. Do not advertise these flows as available until an email/SMS provider is integrated. API-created accounts have an empty display name until profile functionality is extended; the web registration form collects a name.

## Routes

| Method | Route | Access / purpose |
| --- | --- | --- |
| GET | `/categories` | Public categories |
| GET | `/professionals?q=&category=&city=&available=` | Public approved directory |
| GET | `/professionals/{id}` | Public approved profile and reviews |
| GET | `/me` | Current account and owned professional profile ID |
| GET/POST | `/professional` | Read/update owned profile; saves reset approval |
| GET | `/appointments` | Only appointments where the caller is a participant |
| POST | `/appointments` | Request a one-hour visit |
| POST | `/appointments/{id}/action` | Authorized state transition |
| GET | `/inbox` | Conversations involving the caller |
| GET/POST | `/messages/{professionalId}` | Participant-only text conversation |
| POST | `/reviews` | Customer review for own completed appointment |
| GET | `/favorites` | Saved, approved professionals |
| POST | `/favorites/{professionalId}` | Toggle saved professional |
| GET | `/notifications` | Caller’s latest 100 in-app updates |
| POST | `/notifications/read` | Mark caller’s updates read |
| POST | `/report/{professionalId}` | Submit `{ "reason": "..." }` |
| GET | `/blocks` | Blocked professionals |
| POST | `/block/{professionalId}` | Set `{ "blocked": true }` or false |

For customer chat, the authenticated user is always the customer, regardless of supplied `customer`/`customerId`. The profile owner may supply the customer ID to open an existing conversation or appointment relationship. Arbitrary third parties cannot read another customer’s thread.

## Booking contract

```json
{"professionalId":1,"startUtc":"2026-11-01T07:00:00Z","description":"Repair a wall socket","address":"Customer-entered service address"}
```

Send timestamps with a UTC `Z` marker. Display times in EAT (UTC+3). Appointments last one hour, must start on a whole hour during the professional’s configured hours, at least 15 minutes and no more than 90 days ahead. The professional must be approved and accepting requests.

Actions: `confirm`, `decline`, `cancel`, `start`, `complete`, `reschedule`, `accept-time`. Reschedule also sends `proposedStartUtc`. Only the other participant can accept a proposed time. Confirmations acquire a MySQL `FOR UPDATE` lock on the professional row inside a transaction and recheck conflicts. Existing confirmed time remains until an accepted proposal commits. A confirmation declines conflicting pending requests.

Business-rule failures return HTTP 400 with `{ "error": "..." }`; unauthenticated application API access returns 401. Identity validation uses standard validation problem responses. The API is not configured for a separate browser origin; Flutter native clients do not require CORS.
