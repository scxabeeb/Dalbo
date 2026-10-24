# Dispatcher-managed service requests

1. A client signs in and submits a service category, issue description, address, preferred time and optional photo. The client cannot select a professional.
2. The operations team sees incoming requests at `/Dispatch` (administrator access required) and receives an in-app notification.
3. An administrator assigns an approved, available professional in the matching category. The client cannot assign themselves or bypass this step through the API.
4. After assignment, the client can see the professional's profile and contact details and use private chat. Other clients and unassigned professionals cannot access the request or conversation.
5. The assigned professional or dispatcher updates **Assigned → On the way → In progress → Completed**. Clients see status updates and the timestamped timeline; tracking refreshes every 10 seconds on web and mobile. These are status updates, not GPS location or an estimated arrival time.

Reassigning before departure removes the previous professional's access to that request and notifies them. A cancelled request no longer authorizes calls/chat. A completed assignment still permits follow-up communication. If the same client and professional have another valid assignment, that relationship continues to authorize their shared conversation.

Public professional contact browsing and direct appointment creation are disabled at the server level. Previously stored messages or old direct appointments do not grant messaging access. Clients submit new work through the service-request flow.

First administrator setup is documented in [admin-settings.md](admin-settings.md). Smoke coverage in `tests/smoke_test.py` and `tests/dispatch_test.py` requires a disposable, demo-seeded MySQL database with `LOCALPRO_URL` and `LOCALPRO_PASSWORD` configured.
