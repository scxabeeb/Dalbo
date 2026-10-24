using LocalPro.Web.Data;using LocalPro.Web.Domain;using LocalPro.Web.Services;using Microsoft.AspNetCore.Mvc;using Microsoft.AspNetCore.Mvc.RazorPages;using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages;
public class ProductsModel(AppDbContext db,ConfigurationService config):PageModel {
 public List<Product> Items{get;set;}=[];public SiteSettings Settings{get;set;}=new();
 [BindProperty(SupportsGet=true)]public string? Q{get;set;}
 public async Task<IActionResult> OnGetAsync(){Settings=await config.Get();if(!Settings.ProductsEnabled)return NotFound();var query=db.Products.AsNoTracking().Where(p=>p.Active);if(!string.IsNullOrWhiteSpace(Q))query=query.Where(p=>p.Name.Contains(Q)||p.Category.Contains(Q));Items=await query.OrderBy(p=>p.SortOrder).ThenBy(p=>p.Name).Select(p=>new Product{Id=p.Id,Name=p.Name,Description=p.Description,Category=p.Category,Price=p.Price,Stock=p.Stock,ImageContentType=p.ImageContentType,UpdatedUtc=p.UpdatedUtc}).ToListAsync();return Page();}
}
