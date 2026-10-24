using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages.Manage;
[Authorize(Roles="Admin")]
public class UsersModel(AppDbContext db,UserManager<AppUser> users):PageModel {
 public class NewUser {
  [Required,StringLength(100)]public string Name{get;set;}="";
  [Required,EmailAddress,StringLength(200)]public string Email{get;set;}="";
  [Required,MinLength(10)]public string Password{get;set;}="";
 }
 [BindProperty]public NewUser Input{get;set;}=new();
 [BindProperty(SupportsGet=true)]public string? Q{get;set;}
 public List<AppUser> Items{get;set;}=[];public HashSet<string> AdminIds{get;set;}=[];
 [TempData]public string? Notice{get;set;}
 public async Task OnGetAsync(){var query=db.Users.AsNoTracking();if(!string.IsNullOrWhiteSpace(Q))query=query.Where(u=>u.Email!.Contains(Q)||u.DisplayName.Contains(Q));Items=await query.OrderBy(u=>u.Email).Take(100).ToListAsync();AdminIds=(await users.GetUsersInRoleAsync("Admin")).Select(u=>u.Id).ToHashSet();}
 public async Task<IActionResult> OnPostAsync(){if(!ModelState.IsValid){await OnGetAsync();return Page();}var u=new AppUser{UserName=Input.Email.Trim(),Email=Input.Email.Trim(),DisplayName=Input.Name.Trim()};var result=await users.CreateAsync(u,Input.Password);if(!result.Succeeded){foreach(var e in result.Errors)ModelState.AddModelError("",e.Description);await OnGetAsync();return Page();}db.AuditEvents.Add(new(){ActorId=User.FindFirstValue(ClaimTypes.NameIdentifier)!,Action=$"Created user: {u.Email}"});await db.SaveChangesAsync();Notice="User created. They can sign in with their email and password.";return RedirectToPage();}
 public async Task<IActionResult> OnPostRoleAsync(string id,bool admin){var u=await users.FindByIdAsync(id);if(u==null)return NotFound();if(!admin&&id==User.FindFirstValue(ClaimTypes.NameIdentifier)){Notice="You cannot remove your own administrator access.";return RedirectToPage();}var result=admin?await users.AddToRoleAsync(u,"Admin"):await users.RemoveFromRoleAsync(u,"Admin");if(result.Succeeded){await users.UpdateSecurityStampAsync(u);db.AuditEvents.Add(new(){ActorId=User.FindFirstValue(ClaimTypes.NameIdentifier)!,Action=$"User {u.Email}: {(admin?"granted":"removed")} administrator access"});await db.SaveChangesAsync();Notice="Access updated. The user must sign out and back in.";}else Notice=string.Join(" ",result.Errors.Select(e=>e.Description));return RedirectToPage();}
}
