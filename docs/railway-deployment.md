# Railway deployment

Deploy the repository root using `railway.toml`, which selects `src/LocalPro.Web/Dockerfile`. The public service is the ASP.NET Razor Pages website and Flutter API. Flutter's native iOS/Android apps must be built and distributed separately with API_URL pointing at the public HTTPS service.

1. Add a Railway MySQL database service named `MySQL`.
2. Add a web service from `scxabeeb/Dalbo`, branch `main`.
3. Set `ASPNETCORE_ENVIRONMENT=Production`, `SeedDemo=false`, and `ConnectionStrings__Default` using Railway references (not local credentials):

```
Server=${{MySQL.MYSQLHOST}};Port=${{MySQL.MYSQLPORT}};Database=${{MySQL.MYSQLDATABASE}};User=${{MySQL.MYSQLUSER}};Password=${{MySQL.MYSQLPASSWORD}};
```

4. Attach a persistent volume to the web service at `/app/App_Data`. It retains request photos and Data Protection keys used by cookie and mobile token authentication. Run one replica: mobile social sign-in sessions currently use process memory.
5. Generate a Railway HTTPS domain. PORT is provided by Railway. The app honors the proxy's forwarded HTTPS headers only in Railway environments.
6. Startup applies EF Core migrations and initializes service categories/settings. No demo accounts or local customer/provider data are uploaded automatically. Register your real administrator email on the deployed site before granting admin access through the existing grant-admin CLI workflow.
7. Add Google/Facebook/Apple credentials as service secrets and register the generated HTTPS callback URLs; see `social-sign-in.md`.

Deployment healthcheck is `/health`. Database migration failure prevents startup. Keep the MySQL database and web volume when redeploying. Never copy `appsettings.Local.json`, private imports, credentials, or a local database dump into the image.
