using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages.Manage;
[Authorize(Roles="Admin")]
public class ServicesModel(AppDbContext db):PageModel {
 public class ServiceForm {
  public int Id{get;set;}
  [Required,StringLength(80)]public string Name{get;set;}="";
  [Required,StringLength(20)]public string Icon{get;set;}="⌘";
  [Required,StringLength(30)]public string Group{get;set;}="Farsamo";
  [StringLength(300)]public string Description{get;set;}="";
  [Range(0,10000000)]public decimal? VisitFee{get;set;}
  public int SortOrder{get;set;}
  public bool Active{get;set;}=true;
 }
 [BindProperty]public ServiceForm Input{get;set;}=new();
 public List<Category> Items{get;set;}=[];
 [TempData]public string? Notice{get;set;}
 async Task Load()=>Items=await db.Categories.AsNoTracking().OrderBy(c=>c.SortOrder).ToListAsync();
 public async Task<IActionResult> OnGetAsync(int? edit){await Load();if(edit.HasValue){var c=Items.SingleOrDefault(c=>c.Id==edit);if(c==null)return NotFound();Input=new(){Id=c.Id,Name=c.Name,Icon=c.Icon,Group=c.Group,Description=c.Description,VisitFee=c.VisitFee,SortOrder=c.SortOrder,Active=c.Active};}return Page();}
 public async Task<IActionResult> OnPostAsync(){if(await db.Categories.AnyAsync(c=>c.Id!=Input.Id&&c.Name==(Input.Name??"").Trim()))ModelState.AddModelError("","That service name already exists.");if(!ModelState.IsValid){await Load();return Page();}var c=Input.Id==0?new Category():await db.Categories.FindAsync(Input.Id);if(c==null)return NotFound();if(Input.Id==0)db.Categories.Add(c);c.Name=Input.Name.Trim();c.Icon=Input.Icon.Trim();c.Group=Input.Group.Trim();c.Description=(Input.Description??"").Trim();c.VisitFee=Input.VisitFee;c.SortOrder=Input.SortOrder;c.Active=Input.Active;db.AuditEvents.Add(new(){ActorId=User.FindFirstValue(ClaimTypes.NameIdentifier)!,Action=$"Saved service: {c.Name}"});await db.SaveChangesAsync();Notice="Service saved.";return RedirectToPage();}
}
