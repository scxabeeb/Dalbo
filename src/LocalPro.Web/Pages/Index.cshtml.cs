using LocalPro.Web.Data;using LocalPro.Web.Domain;using LocalPro.Web.Services;using Microsoft.AspNetCore.Mvc.RazorPages;using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages;
public class IndexModel(AppDbContext db,RequestService requests):PageModel{
 public List<Category> Categories{get;set;}=[];public List<ServiceRequest> Requests{get;set;}=[];
 public async Task OnGetAsync(){Categories=await db.Categories.Where(c=>c.Active).OrderBy(c=>c.SortOrder).ToListAsync();if(User.Identity?.IsAuthenticated==true)Requests=(await requests.List(User)).Where(r=>r.Status!=ServiceRequestStatus.Completed&&r.Status!=ServiceRequestStatus.Cancelled).Take(3).ToList();}}
