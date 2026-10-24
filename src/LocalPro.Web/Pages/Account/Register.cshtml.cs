using System.ComponentModel.DataAnnotations;using LocalPro.Web.Domain;using Microsoft.AspNetCore.Identity;using Microsoft.AspNetCore.Mvc;using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LocalPro.Web.Pages.Account;
public class RegisterModel(UserManager<AppUser> users,SignInManager<AppUser> signIn,LocalPro.Web.Services.ConfigurationService config):PageModel{
 [BindProperty,Required,StringLength(100)]public string Name{get;set;}="";[BindProperty,Required,EmailAddress]public string Email{get;set;}="";[BindProperty,Required,MinLength(10)]public string Password{get;set;}="";[BindProperty]public bool Terms{get;set;}
 [BindProperty,Required,Compare(nameof(Password))]public string ConfirmPassword{get;set;}="";
 public bool RegistrationEnabled{get;set;}=true;
 public async Task OnGetAsync()=>RegistrationEnabled=(await config.Get()).RegistrationEnabled;
 public async Task<IActionResult> OnPostAsync(){RegistrationEnabled=(await config.Get()).RegistrationEnabled;if(!RegistrationEnabled){ModelState.AddModelError("","New account registration is currently closed.");return Page();}if(!Terms)ModelState.AddModelError("","Accept the service terms to continue.");if(!ModelState.IsValid)return Page();var u=new AppUser{UserName=Email.Trim(),Email=Email.Trim(),DisplayName=Name.Trim()};var result=await users.CreateAsync(u,Password);if(result.Succeeded){await signIn.SignInAsync(u,false);return RedirectToPage("/Index");}foreach(var e in result.Errors)ModelState.AddModelError("",e.Description);return Page();}}
