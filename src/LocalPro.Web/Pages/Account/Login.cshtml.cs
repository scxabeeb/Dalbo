using System.ComponentModel.DataAnnotations;
using LocalPro.Web.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LocalPro.Web.Pages.Account;

public class LoginModel(SignInManager<AppUser> signIn, UserManager<AppUser> users) : PageModel
{
    [BindProperty, Required, EmailAddress]
    public string Email { get; set; } = "";
    [BindProperty, Required]
    public string Password { get; set; } = "";
    [BindProperty]
    public bool RememberMe { get; set; }
    [BindProperty(SupportsGet = true)]
    public string? ReturnUrl { get; set; }

    public IActionResult OnGet() => User.Identity?.IsAuthenticated == true
        ? LocalRedirect(Url.IsLocalUrl(ReturnUrl) ? ReturnUrl! : "/")
        : Page();

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid) return Page();
        var user = await users.FindByEmailAsync(Email.Trim());
        if (user != null)
        {
            var result = await signIn.PasswordSignInAsync(user, Password, RememberMe, lockoutOnFailure: true);
            if (result.Succeeded)
                return LocalRedirect(Url.IsLocalUrl(ReturnUrl) ? ReturnUrl! : "/");
        }
        ModelState.AddModelError("", "Sign-in failed. Check your email and password or try again later.");
        return Page();
    }
}
