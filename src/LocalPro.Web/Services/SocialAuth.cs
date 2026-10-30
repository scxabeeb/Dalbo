using System.Net.Http.Headers;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Memory;
using LocalPro.Web.Domain;

namespace LocalPro.Web.Services;

public static class SocialAuth
{
    public static void AddSocialAuth(this IServiceCollection services, IConfiguration config)
    {
        services.AddAuthentication();
        services.AddMemoryCache();
        services.AddSingleton<MobileSocialSessions>();
        foreach (var provider in new[] { "Google", "Facebook" })
        {
            var section = config.GetSection($"Authentication:{provider}");
            if (string.IsNullOrWhiteSpace(section["ClientId"]) || string.IsNullOrWhiteSpace(section["ClientSecret"])) continue;
            var google = provider == "Google";
            services.AddAuthentication().AddOAuth(provider, provider, o =>
            {
                o.SignInScheme = IdentityConstants.ExternalScheme;
                o.ClientId = section["ClientId"]!;
                o.ClientSecret = section["ClientSecret"]!;
                o.CallbackPath = google ? "/signin-google" : "/signin-facebook";
                o.AuthorizationEndpoint = google ? "https://accounts.google.com/o/oauth2/v2/auth" : "https://www.facebook.com/v23.0/dialog/oauth";
                o.TokenEndpoint = google ? "https://oauth2.googleapis.com/token" : "https://graph.facebook.com/v23.0/oauth/access_token";
                o.UserInformationEndpoint = google ? "https://openidconnect.googleapis.com/v1/userinfo" : "https://graph.facebook.com/v23.0/me?fields=id,name,email";
                o.UsePkce = google;
                if (google) o.Scope.Add("openid");
                o.Scope.Add("email");
                o.Scope.Add(google ? "profile" : "public_profile");
                o.ClaimActions.MapJsonKey(ClaimTypes.NameIdentifier, google ? "sub" : "id");
                o.ClaimActions.MapJsonKey(ClaimTypes.Name, "name");
                o.ClaimActions.MapJsonKey(ClaimTypes.Email, "email");
                o.Events.OnCreatingTicket = async ctx =>
                {
                    using var request = new HttpRequestMessage(HttpMethod.Get, ctx.Options.UserInformationEndpoint);
                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ctx.AccessToken);
                    using var response = await ctx.Backchannel.SendAsync(request, ctx.HttpContext.RequestAborted);
                    response.EnsureSuccessStatusCode();
                    using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
                    if (google && (!document.RootElement.TryGetProperty("email_verified", out var verified) || verified.ValueKind != JsonValueKind.True))
                        throw new AuthenticationFailureException("A verified email is required.");
                    ctx.RunClaimActions(document.RootElement);
                };
                o.Events.OnRemoteFailure = ctx =>
                {
                    ctx.HandleResponse();
                    ctx.Response.Redirect("/Account/Social?handler=Failed");
                    return Task.CompletedTask;
                };
            });
        }
    }

    public static void MapSocialAuth(this WebApplication app)
    {
        app.MapGet("/api/social/providers", async (IAuthenticationSchemeProvider schemes) =>
            (await schemes.GetAllSchemesAsync()).Where(s => s.DisplayName != null).Select(s => new { name = s.Name }));
        app.MapPost("/api/social/mobile/start", async (MobileStart input, IAuthenticationSchemeProvider schemes, MobileSocialSessions sessions) =>
        {
            if (string.IsNullOrEmpty(input.Secret) || input.Secret.Length < 40 || input.Secret.Length > 100 || !(await schemes.GetAllSchemesAsync()).Any(s => s.DisplayName != null && s.Name == input.Provider))
                return Results.BadRequest(new { error = "Social sign-in is not configured." });
            var ticket = sessions.Create(input.Secret);
            return Results.Ok(new { ticket, path = $"/Account/Social?provider={Uri.EscapeDataString(input.Provider)}&mobile={ticket}" });
        }).RequireRateLimiting("auth");
        app.MapPost("/api/social/mobile/complete", async (MobileComplete input, MobileSocialSessions sessions, UserManager<AppUser> users, SignInManager<AppUser> signIn) =>
        {
            var result = sessions.Take(input.Ticket, input.Secret);
            if (result == null) return Results.BadRequest(new { error = "Sign-in expired. Please try again." });
            if (result.UserId == null) return Results.Json(new { pending = true }, statusCode: 202);
            var user = await users.FindByIdAsync(result.UserId);
            if (user == null || !await signIn.CanSignInAsync(user) || await users.IsLockedOutAsync(user)) return Results.Unauthorized();
            return Results.SignIn(await signIn.CreateUserPrincipalAsync(user), authenticationScheme: IdentityConstants.BearerScheme);
        }).RequireRateLimiting("social-poll");
    }
}

public record MobileStart(string Provider, string Secret);
public record MobileComplete(string Ticket, string Secret);
public sealed class MobileSocialSessions(IMemoryCache cache)
{
    public sealed class Session(byte[] hash) { public byte[] Hash { get; } = hash; public string? UserId { get; set; } public bool Consumed { get; set; } }
    public string Create(string secret)
    {
        var ticket = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        cache.Set("social:" + ticket, new Session(SHA256.HashData(Encoding.UTF8.GetBytes(secret))), TimeSpan.FromMinutes(5));
        return ticket;
    }
    public bool Complete(string ticket, string id)
    {
        if (!cache.TryGetValue<Session>("social:" + ticket, out var session) || session == null) return false;
        lock (session) { if (session.UserId != null) return false; session.UserId = id; return true; }
    }
    public Session? Take(string ticket, string secret)
    {
        if (string.IsNullOrEmpty(ticket) || string.IsNullOrEmpty(secret) || ticket.Length > 100 || secret.Length > 100 || !cache.TryGetValue<Session>("social:" + ticket, out var session) || session == null) return null;
        lock (session)
        {
            if (session.Consumed || !CryptographicOperations.FixedTimeEquals(session.Hash, SHA256.HashData(Encoding.UTF8.GetBytes(secret)))) return null;
            if (session.UserId != null) { session.Consumed = true; cache.Remove("social:" + ticket); return session; }
            return new Session(session.Hash);
        }
    }
}
