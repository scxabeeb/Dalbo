# Verification — 23 October 2026

- ASP.NET solution build: passed, zero compile errors. NuGet reported inability to reach its service/vulnerability feed; cached dependencies were used.
- EF Core migrations: applied successfully to an isolated MySQL 9.5 instance.
- Python integration suite: 7 tests passed, covering directory filtering/DTO privacy, authentication, approval gating, private messages, booking concurrency and rescheduling, review eligibility, favorites, notifications, blocking/unblocking and administrator access.
- Flutter analysis: no issues found.
- Flutter tests: 2 passed (signed-out account screen and EAT timestamp conversion).
- Android debug APK: built successfully from final source.
- Browser: inspected home and profile layouts, tested plumbing filter (two matching professionals), and confirmed appointment navigation redirects a signed-out visitor to login.
- Original preview screenshot: web-preview.png (captured before the app was renamed to Dalbo).

No Android device/emulator was connected, so the APK was not exercised on a device. iOS compilation/signing, MySQL 8.4 Docker runtime, narrow-screen browser rendering, production deployment, and live vulnerability audit were not verified. The source includes responsive breakpoints; they still need device QA.

Local verification processes were stopped after testing. Follow README.md to start your development environment.
