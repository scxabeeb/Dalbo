using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages.Manage;
[Authorize(Roles="Admin")]
public class IndexModel(AppDbContext db):PageModel {
 public int Requests{get;set;} public int Waiting{get;set;} public int Professionals{get;set;} public int Customers{get;set;}
 public List<ServiceRequest> Recent{get;set;}=[];
 public List<CurrencyCollection> Collections{get;set;}=[];
 public async Task OnGetAsync(){Requests=await db.ServiceRequests.CountAsync();Waiting=await db.ServiceRequests.CountAsync(r=>r.Status==ServiceRequestStatus.Received);Professionals=await db.Professionals.CountAsync(p=>p.Approved);Customers=await db.Users.CountAsync();Recent=await db.ServiceRequests.AsNoTracking().Include(r=>r.Category).Include(r=>r.Customer).OrderByDescending(r=>r.CreatedUtc).Take(6).ToListAsync();Collections=await db.Set<ServicePayment>().GroupBy(p=>p.ServiceInvoice.Currency).Select(g=>new CurrencyCollection(g.Key,g.Sum(p=>p.Amount))).ToListAsync();}
 public record CurrencyCollection(string Currency,decimal Total);
}
