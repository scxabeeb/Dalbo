using LocalPro.Web.Services;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Authentication;
using System.Collections.Concurrent;

static void Check(bool value, string message) { if (!value) throw new Exception(message); }
using var cache = new MemoryCache(new MemoryCacheOptions());
var sessions = new MobileSocialSessions(cache);
var secret = new string('a', 44);
var ticket = sessions.Create(secret);
Check(sessions.Take(ticket, new string('b', 44)) == null, "Wrong secret accepted");
Check(sessions.Take(ticket, secret)?.UserId == null, "Pending session incorrectly authenticated");
Check(!sessions.Complete("missing", "user"), "Missing ticket accepted");
Check(sessions.Complete(ticket, "user"), "Valid completion failed");
Check(!sessions.Complete(ticket, "other"), "Completed identity overwritten");
var results = new ConcurrentBag<string>();
Parallel.For(0, 100, _ => { var session = sessions.Take(ticket, secret); if (session?.UserId != null) results.Add(session.UserId); });
Check(results.Count == 1 && results.Single() == "user", "Ticket was not single-use under concurrent redemption");
Check(sessions.Take(ticket, secret) == null, "Consumed ticket replayed");
var expired = sessions.Create(secret);
cache.Remove("social:" + expired);
Check(sessions.Take(expired, secret) == null, "Expired ticket accepted");
var services = new ServiceCollection();
services.AddLogging();services.AddSocialAuth(new ConfigurationBuilder().Build());
using var container = services.BuildServiceProvider();
Check(!(await container.GetRequiredService<IAuthenticationSchemeProvider>().GetAllSchemesAsync()).Any(s=>s.DisplayName!=null), "Unconfigured provider advertised");
Console.WriteLine("PASS: secret validation, pending state, immutable identity, concurrent single-use redemption, replay/expiry rejection, provider discovery");

var appleServices = new ServiceCollection();
appleServices.AddLogging();
appleServices.AddSocialAuth(new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> {
    ["Authentication:Apple:ClientId"] = "com.example.dalbo.web",
    ["Authentication:Apple:ClientSecret"] = "placeholder-test-jwt"
}).Build());
using var appleContainer = appleServices.BuildServiceProvider();
var appleSchemes = await appleContainer.GetRequiredService<IAuthenticationSchemeProvider>().GetAllSchemesAsync();
Check(appleSchemes.Single(s => s.DisplayName != null).Name == "Apple", "Configured Apple sign-in not discoverable");
var options = appleContainer.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<Microsoft.AspNetCore.Authentication.OpenIdConnect.OpenIdConnectOptions>>().Get("Apple");
Check(options.Authority == "https://appleid.apple.com" && options.RequireHttpsMetadata, "Apple issuer must use trusted HTTPS metadata");
Check(options.CallbackPath == "/signin-apple" && options.ResponseMode == "form_post" && options.ResponseType == "code", "Apple authorization protocol incorrect");
Check(options.ProtocolValidator.RequireNonce && options.TokenValidationParameters.ValidateIssuer && options.TokenValidationParameters.ValidateAudience && options.TokenValidationParameters.ValidateLifetime && options.TokenValidationParameters.RequireSignedTokens, "Apple token validation protections disabled");
Check(options.CorrelationCookie.SameSite == Microsoft.AspNetCore.Http.SameSiteMode.None && options.CorrelationCookie.SecurePolicy == Microsoft.AspNetCore.Http.CookieSecurePolicy.Always, "Apple POST correlation cookie is not secure");
var context = new Microsoft.AspNetCore.Authentication.OpenIdConnect.TokenValidatedContext(new Microsoft.AspNetCore.Http.DefaultHttpContext(), appleSchemes.Single(s=>s.Name=="Apple"), options, new System.Security.Claims.ClaimsPrincipal(new System.Security.Claims.ClaimsIdentity()), new AuthenticationProperties());
await options.Events.OnTokenValidated(context);
Check(context.Result?.Failure != null, "Apple identity without verified email was accepted");
var verifiedContext = new Microsoft.AspNetCore.Authentication.OpenIdConnect.TokenValidatedContext(new Microsoft.AspNetCore.Http.DefaultHttpContext(), appleSchemes.Single(s=>s.Name=="Apple"), options, new System.Security.Claims.ClaimsPrincipal(new System.Security.Claims.ClaimsIdentity(new[]{new System.Security.Claims.Claim("email_verified","true")})), new AuthenticationProperties());
await options.Events.OnTokenValidated(verifiedContext);
Check(verifiedContext.Result?.Failure == null, "Verified Apple email rejected");
Console.WriteLine("PASS: Apple discovery, secure authorization configuration, token validation requirements and verified-email enforcement");
