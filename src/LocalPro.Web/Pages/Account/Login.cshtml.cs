using System.ComponentModel.DataAnnotations;using LocalPro.Web.Domain;using Microsoft.AspNetCore.Identity;using Microsoft.AspNetCore.Mvc;using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LocalPro.Web.Pages.Account;
public class LoginModel(SignInManager<AppUser> signIn):PageModel{
 [BindProperty,Required,EmailAddress] public string Email{get;set;}="";[BindProperty,Required]public string Password{get;set;}="";[BindProperty(SupportsGet=true)]public string? ReturnUrl{get;set;}
 public async Task<IActionResult> OnPostAsync(){if(!ModelState.IsValid)return Page();var result=await signIn.PasswordSignInAsync(Email,Password,false,true);if(result.Succeeded)return LocalRedirect(Url.IsLocalUrl(ReturnUrl)?ReturnUrl!:"/");ModelState.AddModelError("","Sign-in failed. Check your details or try again later.");return Page();}}
