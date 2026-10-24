# Accounts and administration

Customers can register with their name, email and password on `/Account/Register`, then sign in at `/Account/Login`. The mobile app provides the same flow in the Account tab, including password confirmation. Passwords require at least 10 characters, uppercase and lowercase letters, a number and a symbol. Web sessions use HttpOnly cookies; mobile sessions use bearer tokens and secure refresh-token storage.

## First administrator

Register the administrator's email normally. From the repository root, grant that existing account access using the local CLI:

```sh
ASPNETCORE_ENVIRONMENT=Development dotnet run --project src/LocalPro.Web --no-launch-profile -- --grant-admin=you@example.com
```

Replace the example email with the intended administrator. This command exits after granting the role; it does not start a second server. Sign out and sign in again to refresh account permissions. Public registration always creates a regular member; it never grants administrator access.

## Administration pages

- `/Manage/Settings`: app name, tagline, primary and accent colors, logo, default city, currency code, contact email/phone, home headline/description, registration and catalog visibility.
- `/Manage/Products`: add/edit products, prices, stock, categories, descriptions, photos and display order. Archive or republish products without deleting data.
- `/Manage/Services`: create/edit services, groups, descriptions, icons, visit fees, visibility and order. Edits persist across restarts.
- `/Manage/Users`: search accounts, create users, and grant/remove administrator access. Administrators cannot remove their own access. Changing a role invalidates that user’s existing web session.
- `/Dispatch` and `/Admin`: existing requests, professional approvals and reports.

The website header shows **Settings** for administrators. The mobile Account tab links administrators to the management website; a separate website login is required. Mobile users can browse published products in the Products tab. Product catalogs display pricing and availability; checkout and inventory reservations are not implemented.

Settings and image bytes are stored in MySQL using EF Core. Logo and product uploads accept PNG/JPEG files up to 2 MB. Mobile branding refreshes on app opening/resume and home refresh. Web branding updates on the next page load. The installed native app label and home-screen icon remain build-time assets; changing them requires a new signed app build.

Registration may be disabled without preventing existing users from signing in or administrators from creating accounts. Currency settings label catalog prices and do not convert stored monetary values.

## Verification

Build with `dotnet build src/LocalPro.Web`. Analyze mobile with `flutter analyze` inside `mobile/`.

Run `tests/configuration_test.py` only against a disposable, demo-seeded MySQL database. Set `LOCALPRO_URL` and `LOCALPRO_PASSWORD` to its URL and demo password. Tests cover email registration/login, authorization and CSRF, branding and image validation, product editing/archiving, registration controls, service edits and admin-created accounts. Never point these mutation tests at a production database.
