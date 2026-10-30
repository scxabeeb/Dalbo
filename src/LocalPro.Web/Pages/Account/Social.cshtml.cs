using System.Security.Claims;
using LocalPro.Web.Domain;
using LocalPro.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LocalPro.Web.Pages.Account;
public class SocialModel(SignInManager<AppUser> signIn, UserManager<AppUser> users, IAuthenticationSchemeProvider schemes, ConfigurationService config, MobileSocialSessions sessions) : PageModel
{
    [BindProperty(SupportsGet = true)] public string Provider { get; set; } = "";
    [BindProperty(SupportsGet = true)] public string? Mobile { get; set; }
    [BindProperty(SupportsGet = true)] public string? ReturnUrl { get; set; }
    [BindProperty] public bool Terms { get; set; }
    public string? Error { get; set; }
    public bool Confirm { get; set; }
    public bool Finished { get; set; }
    public async Task OnGetAsync()
    {
        if (!(await schemes.GetAllSchemesAsync()).Any(s => s.DisplayName != null && s.Name == Provider))
            Error = "This social sign-in provider has not been configured yet. Please use email sign-in.";
    }
    public void OnGetFailed() => Error = "Social sign-in was cancelled or could not be completed. Please try again.";
    public async Task<IActionResult> OnPostChallengeAsync()
    {
        await OnGetAsync();
        if (Error != null) return Page();
        var properties = signIn.ConfigureExternalAuthenticationProperties(Provider, Url.Page("/Account/Social", "Callback")!);
        properties.Items["mobile"] = Mobile;
        properties.Items["return"] = Url.IsLocalUrl(ReturnUrl) ? ReturnUrl : "/";
        return Challenge(properties, Provider);
    }
    public async Task<IActionResult> OnGetCallbackAsync()
    {
        var info = await signIn.GetExternalLoginInfoAsync();
        if (info == null) { Error = "Unable to complete social sign-in. Please try again."; return Page(); }
        var user = await users.FindByLoginAsync(info.LoginProvider, info.ProviderKey);
        if (user != null) return await Finish(user);
        Confirm = true;
        return Page();
    }
    public async Task<IActionResult> OnPostCreateAsync()
    {
        Confirm = true;
        var info = await signIn.GetExternalLoginInfoAsync();
        if (info == null) { Confirm = false; Error = "Sign-in expired. Please start again."; return Page(); }
        if (!Terms) { Error = "Accept the terms and privacy policy to create your account."; return Page(); }
        var existing = await users.FindByLoginAsync(info.LoginProvider, info.ProviderKey);
        if (existing != null) return await Finish(existing);
        if (!(await config.Get()).RegistrationEnabled) { Error = "New account registration is currently closed."; return Page(); }
        var email = info.Principal.FindFirstValue(ClaimTypes.Email);
        if (string.IsNullOrWhiteSpace(email) || !new System.ComponentModel.DataAnnotations.EmailAddressAttribute().IsValid(email))
        { Error = "Your provider did not share an email address. Please register using email instead."; return Page(); }
        if (await users.FindByEmailAsync(email) != null)
        { Error = "An account already uses this email. Sign in with its existing method. Social accounts are not automatically linked."; return Page(); }
        var name = info.Principal.FindFirstValue(ClaimTypes.Name) ?? email.Split('@')[0];
        var user = new AppUser { UserName = email, Email = email, DisplayName = name[..Math.Min(name.Length, 100)] };
        var created = await users.CreateAsync(user);
        if (!created.Succeeded) { Error = "Unable to create the account. Please use email registration."; return Page(); }
        var linked = await users.AddLoginAsync(user, info);
        if (!linked.Succeeded) { await users.DeleteAsync(user); Error = "Unable to connect your social account. Please try again."; return Page(); }
        return await Finish(user);
    }
    private async Task<IActionResult> Finish(AppUser user)
    {
        if (!await signIn.CanSignInAsync(user) || await users.IsLockedOutAsync(user))
        { Error = "Unable to sign in. Please try again later."; return Page(); }
        var external = await HttpContext.AuthenticateAsync(IdentityConstants.ExternalScheme);
        string? ticket = null;
        external.Properties?.Items.TryGetValue("mobile", out ticket);
        string? target = null;
        external.Properties?.Items.TryGetValue("return", out target);
        await HttpContext.SignOutAsync(IdentityConstants.ExternalScheme);
        if (!string.IsNullOrEmpty(ticket))
        {
            if (!sessions.Complete(ticket, user.Id)) Error = "Mobile sign-in expired. Return to the app and try again.";
            else Finished = true;
            return Page();
        }
        await signIn.SignInAsync(user, false);
        return LocalRedirect(Url.IsLocalUrl(target) ? target! : "/");
    }
}
