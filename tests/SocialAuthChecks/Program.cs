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
