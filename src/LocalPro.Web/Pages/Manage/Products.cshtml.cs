using System.Security.Claims;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using LocalPro.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages.Manage;
[Authorize(Roles="Admin")]
public class ProductsModel(AppDbContext db):PageModel {
 [BindProperty] public Product Input {get;set;}=new();
 [BindProperty] public IFormFile? ImageFile {get;set;}
 [BindProperty] public bool RemoveImage {get;set;}
 [TempData] public string? Notice {get;set;}
 public List<Product> Items {get;set;}=[];
 async Task Load()=>Items=await db.Products.AsNoTracking().OrderBy(p=>p.SortOrder).ThenBy(p=>p.Name).Select(p=>new Product{Id=p.Id,Name=p.Name,Price=p.Price,Stock=p.Stock,Category=p.Category,Active=p.Active}).ToListAsync();
 public async Task<IActionResult> OnGetAsync(int? edit){await Load();if(edit.HasValue){var p=await db.Products.AsNoTracking().SingleOrDefaultAsync(p=>p.Id==edit);if(p==null)return NotFound();Input=p;}return Page();}
 public async Task<IActionResult> OnPostAsync(){
  if(!ModelState.IsValid){await Load();return Page();}
  (byte[] Bytes,string Type)? image=null;if(ImageFile!=null){try{image=await ConfigurationService.ReadImage(ImageFile);}catch(RuleException e){ModelState.AddModelError("",e.Message);await Load();return Page();}}
  var p=Input.Id==0?new Product():await db.Products.FindAsync(Input.Id);if(p==null)return NotFound();if(Input.Id==0)db.Products.Add(p);
  p.Name=Input.Name.Trim();p.Description=(Input.Description??"").Trim();p.Category=(Input.Category??"").Trim();p.Price=Input.Price;p.Stock=Input.Stock;p.Active=Input.Active;p.SortOrder=Input.SortOrder;p.UpdatedUtc=DateTime.UtcNow;
  if(RemoveImage){p.Image=null;p.ImageContentType=null;}if(image.HasValue){p.Image=image.Value.Bytes;p.ImageContentType=image.Value.Type;}
  db.AuditEvents.Add(new(){ActorId=User.FindFirstValue(ClaimTypes.NameIdentifier)!,Action=$"Saved product: {p.Name}"});await db.SaveChangesAsync();Notice="Product saved.";return RedirectToPage();
 }
 public async Task<IActionResult> OnPostToggleAsync(int id){var p=await db.Products.FindAsync(id);if(p==null)return NotFound();p.Active=!p.Active;p.UpdatedUtc=DateTime.UtcNow;db.AuditEvents.Add(new(){ActorId=User.FindFirstValue(ClaimTypes.NameIdentifier)!,Action=$"Product {id}: {(p.Active?"published":"archived")}"});await db.SaveChangesAsync();return RedirectToPage();}
}
