using LocalPro.Web.Data;using LocalPro.Web.Domain;using LocalPro.Web.Services;using Microsoft.AspNetCore.Mvc;using Microsoft.AspNetCore.Mvc.RazorPages;using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages;
public class IndexModel(Marketplace marketplace,AppDbContext db):PageModel{
 [BindProperty(SupportsGet=true)] public string? Q{get;set;} [BindProperty(SupportsGet=true)] public int? Category{get;set;} [BindProperty(SupportsGet=true)] public string? City{get;set;} [BindProperty(SupportsGet=true)] public bool Available{get;set;}
 public List<Domain.Professional> Professionals{get;set;}=[];public List<Category> Categories{get;set;}=[];
 public async Task OnGetAsync(){Categories=await db.Categories.ToListAsync();Professionals=await marketplace.Search(Q,Category,City,Available);}
}
