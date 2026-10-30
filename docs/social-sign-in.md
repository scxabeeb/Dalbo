# Social sign-in: web and Flutter

Google, Facebook and Apple sign-in share the ASP.NET Identity account store. Only configured providers appear on Login/Register and the Flutter account screen. Existing email/password login remains available. No database migration is required: Identity's existing AspNetUserLogins table stores provider links.

## Configure credentials

Create a Google OAuth **Web application** client and/or a Meta app with **Facebook Login**. Configure the consent screen, privacy policy and permitted test users. For public use complete the provider's publishing requirements.

Set these on the server using environment variables or the ignored development `src/LocalPro.Web/appsettings.Local.json`. Do not commit real credentials or put secrets in Flutter.

```
Authentication__Google__ClientId
Authentication__Google__ClientSecret
Authentication__Facebook__ClientId
Authentication__Facebook__ClientSecret
```

Register the exact callback URLs:

| Provider | Local callback | Production callback |
| --- | --- | --- |
| Google | http://localhost:5080/signin-google | https://YOUR-DOMAIN/signin-google |
| Facebook | https://YOUR-DEV-DOMAIN/signin-facebook | https://YOUR-DOMAIN/signin-facebook |

Google supports localhost development. For Facebook and physical phones use a reachable HTTPS development host approved in the provider console. Set Flutter's API_URL to the same backend origin. Restart the backend after changing configuration. Credentials are deliberately not exposed in public settings or editable through branding settings.

## Behaviour and security

Users approve access to basic name and email in their system browser, then accept the site's terms before creating an account. New social accounts are ordinary members with no administrator access. Registration-disabled settings also apply to social registration; existing linked accounts can still log in.

Accounts match the provider's stable user ID. An existing email account is **not automatically linked** to a social identity. Users with that email must use their existing login method; account linking is not implemented in this version. Imported professional records are not claimed through social email matching.

OAuth middleware protects state/correlation and uses PKCE with Google. Google must return a verified email; Facebook must return an email to register. No provider access tokens are persisted. Failed or cancelled authorizations show a retry message.

Mobile opens the server flow in an external browser. A random 256-bit secret stays in the app and is sent only in POST bodies; the browser URL carries a separate random ticket. The server stores only the secret hash, expires the session after five minutes and releases Identity bearer/refresh tokens once. Tokens use the existing secure-storage flow. Browser completion tells the user to return to the app. Backing out of the mobile screen cancels local polling. Pending sessions live in process memory: restarting the backend requires retrying; multi-server deployments must replace this with an atomic shared store.

## Validation

Build the ASP.NET project, run Flutter analysis/tests, and check that `/api/social/providers` returns no unconfigured providers. Test provider redirect generation with temporary non-production credentials. Full authorization requires genuine registered provider credentials and a consenting provider test account; it cannot be verified using placeholder IDs.

References: [ASP.NET external authentication](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/social/), [Google OAuth web server flow](https://developers.google.com/identity/protocols/oauth2/web-server), [Facebook Login flow](https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/).

## Sign in with Apple

Apple is also supported by the same web and Flutter browser flow. Set these server-only values and restart:

```
Authentication__Apple__ClientId
Authentication__Apple__ClientSecret
```

`ClientId` is your Apple **Services ID**, configured for Sign in with Apple and associated with a primary App ID in your Apple Developer account. Register your website domain and the exact HTTPS return URL `https://YOUR-DOMAIN/signin-apple`. Apple does not accept localhost/IP return URLs: use your deployed HTTPS domain for web and the mobile API_URL.

`ClientSecret` is an **ES256-signed JWT**, not an Apple ID password. Generate it using your Sign in with Apple `.p8` private key, Key ID, Team ID and Services ID. Apple limits its lifetime to six months; rotate it before expiry. Keep the `.p8` key and JWT out of Git and Flutter. Use Railway service variables for production values.

The backend uses Microsoft's OpenID Connect middleware and Apple's discovery/JWKS endpoints to validate token signatures, issuer, audience, expiration and nonce. Apple requires a cross-site form POST callback; correlation and nonce cookies use Secure/SameSite=None. Apple relay email addresses are supported. The signed email must be verified. Apple's optional first-login name form field is not trusted as identity data; the initial display name uses the email prefix and can be changed in the account profile. No native Flutter plugin or mobile secret is required: provider discovery automatically displays Apple when configured.

Full Apple sign-in testing requires real Apple Developer credentials, a registered HTTPS return URL and an Apple test account. [Apple authorization documentation](https://developer.apple.com/documentation/signinwithapplerestapi/request-an-authorization-to-the-sign-in-with-apple-server.) and [Apple client-secret/token documentation](https://developer.apple.com/documentation/SigninwithAppleRESTAPI/Generate-and-validate-tokens).
