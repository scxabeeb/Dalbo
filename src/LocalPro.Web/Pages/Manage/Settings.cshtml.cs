using System.Security.Claims;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using LocalPro.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LocalPro.Web.Pages.Manage;
[Authorize(Roles="Admin")]
public class SettingsModel(AppDbContext db,ConfigurationService config):PageModel {
 [BindProperty] public SiteSettings Input {get;set;}=new();
 [BindProperty] public IFormFile? LogoFile {get;set;}
 [BindProperty] public bool ResetLogo {get;set;}
 [TempData] public string? Notice {get;set;}
 public string LogoUrl {get;set;}="/api/settings/logo";
 public async Task OnGetAsync(){Input=await config.Get();}
 public async Task<IActionResult> OnPostAsync(){
  if(!ModelState.IsValid)return Page();
  (byte[] Bytes,string Type)? image=null;
  if(LogoFile!=null){try{image=await ConfigurationService.ReadImage(LogoFile);}catch(RuleException e){ModelState.AddModelError("",e.Message);return Page();}}
  var s=await db.SiteSettings.FindAsync(1);if(s==null){s=new();db.SiteSettings.Add(s);}
  s.AppName=Input.AppName.Trim();s.Tagline=(Input.Tagline??"").Trim();s.City=Input.City.Trim();s.PrimaryColor=Input.PrimaryColor;s.AccentColor=Input.AccentColor;s.HeroTitle=(Input.HeroTitle??"").Trim();s.HeroDescription=(Input.HeroDescription??"").Trim();s.Currency=Input.Currency;s.ContactEmail=Input.ContactEmail?.Trim();s.ContactPhone=Input.ContactPhone?.Trim();s.RegistrationEnabled=Input.RegistrationEnabled;s.ProductsEnabled=Input.ProductsEnabled;s.UpdatedUtc=DateTime.UtcNow;
  if(ResetLogo){s.Logo=null;s.LogoContentType=null;}if(image.HasValue){s.Logo=image.Value.Bytes;s.LogoContentType=image.Value.Type;}
  db.AuditEvents.Add(new(){ActorId=User.FindFirstValue(ClaimTypes.NameIdentifier)!,Action="Updated application settings and branding"});await db.SaveChangesAsync();Notice="Settings saved. Web branding is updated; mobile refreshes branding when opened or refreshed.";return RedirectToPage();
 }
}
