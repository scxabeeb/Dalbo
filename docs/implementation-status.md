# Implementation status

Your selected stack supersedes the React/Node/PostgreSQL suggestions in the product brief.

## Working development features

- Responsive Razor Pages website and Flutter Android/iOS source using one ASP.NET API.
- EF Core models and checked-in MySQL migrations; no in-memory database fallback.
- Email/password accounts with Identity hashing, lockout, cookie sessions, mobile bearer access and refresh tokens.
- Configurable categories through administration; location fields and manual location search.
- Professional registration/editing, public business contacts, experience, rate, working hours, acceptance setting, approval and suspension.
- Approved directory, category/location/text search, request-acceptance filter, profile detail and real review aggregates.
- Saved professionals on web and mobile.
- Private text chat with five-second refresh, message timestamps and participant checks.
- Booking requests, confirmation/decline, cancellation, start/completion, reschedule proposals and acceptance.
- MySQL transaction locking and conflict checks for confirmations, with audit events.
- Completed-appointment review eligibility and one-review-per-appointment constraint.
- In-app message and appointment updates with mark-as-read controls.
- User reporting, message blocking/unblocking and administrative report resolution.
- Administrator profile approvals/suspension, category creation, activity counts and audit history.
- Generated Android and iOS projects, Docker development setup, API guide and integration checks.

## Remaining scope from the full brief

These features are **not implemented** and must not be presented as working:

- Phone OTP authentication, verified-contact onboarding, production email/SMS delivery, password recovery UI, administrator MFA enforcement and account deletion/export workflows.
- Profile photo/portfolio uploads, chat or booking image attachments, malware/file validation and object storage.
- SignalR/WebSocket delivery, message read receipts, typing indicators, push notifications, appointment reminders, notification preferences and quiet hours.
- Date-slot availability search, weekly schedules, holidays/time off, custom duration, travel buffers, request expiry jobs and configurable cancellation cutoffs. Current scheduling uses daily start/end hours and one-hour visits.
- Maps, device geolocation, configurable currencies/languages, translation catalogs and location administration.
- Professional review responses and review moderation/reporting. Current reports concern professional profiles.
- Full customer settings, favorites badges, image-based avatars and a complete support workflow.
- Qualified identity verification; approval means publication review only.
- Full accessibility audit, load/performance tests, attachment security tests, production backups/restoration, deployment monitoring, analytics and store release signing.
- Payments, subscriptions and job bidding, which remain explicitly out of MVP scope.

The web privacy/terms page is provisional text for development and requires launch-market review and a real support contact. Use fictional data in this preview.

## Verification limits

The web build and database integration checks run locally; Flutter analysis/tests and an Android debug APK are checked separately. iOS compilation/signing, a physical-device end-to-end session, and a MySQL 8.4 container run require their corresponding tools/environments. NuGet restored dependencies from the local cache; live vulnerability-feed access was unavailable during the initial build.
