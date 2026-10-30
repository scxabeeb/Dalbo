using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using LocalPro.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Pages.Manage;
[Authorize(Roles="Admin")]
public class PaymentsModel(AppDbContext db,PaymentService payments,ConfigurationService config):PageModel {
 public List<ServiceInvoice> Invoices{get;set;}=[];
 public List<ServiceRequest> Requests{get;set;}=[];
 public ServiceInvoice? Selected{get;set;}
 public string Currency{get;set;}="USD";
 public decimal Collected{get;set;} public decimal Outstanding{get;set;}
 [BindProperty(SupportsGet=true)]public int? Invoice{get;set;}
 [TempData]public string? Notice{get;set;}
 [TempData]public string? Error{get;set;}
 public async Task OnGetAsync(){Currency=(await config.Get()).Currency;Invoices=await payments.Query.AsNoTracking().OrderByDescending(i=>i.CreatedUtc).Take(200).ToListAsync();Requests=await db.ServiceRequests.AsNoTracking().Include(r=>r.Customer).Include(r=>r.Category).Where(r=>r.Status!=ServiceRequestStatus.Cancelled&&!db.Set<ServiceInvoice>().Any(i=>i.ServiceRequestId==r.Id)).OrderByDescending(r=>r.CreatedUtc).Take(200).ToListAsync();if(Invoice.HasValue)Selected=await payments.Query.AsNoTracking().SingleOrDefaultAsync(i=>i.Id==Invoice);Collected=await db.Set<ServicePayment>().Where(p=>p.ServiceInvoice.Currency==Currency).SumAsync(p=>(decimal?)p.Amount)??0;var totals=await db.Set<ServiceInvoice>().Where(i=>i.Currency==Currency&&!i.Voided).SumAsync(i=>(decimal?)i.Total)??0;Outstanding=totals-Collected;}
 public async Task<IActionResult> OnPostCreateAsync(int requestId,decimal total,string? notes){if(!ModelState.IsValid){Error="Enter a valid request and invoice total.";return RedirectToPage();}try{await payments.Create(User,requestId,total,notes);Notice="Invoice created. The customer can now view the balance.";}catch(RuleException ex){Error=ex.Message;}return RedirectToPage();}
 public async Task<IActionResult> OnPostRecordAsync(int invoiceId,decimal amount,string? method,string? reference,string? key){if(!ModelState.IsValid){Error="Enter a valid payment amount.";return RedirectToPage(new{invoice=invoiceId});}try{await payments.Record(User,invoiceId,amount,method,reference,key);Notice="Payment recorded and receipt added.";}catch(RuleException ex){Error=ex.Message;}return RedirectToPage(new{invoice=invoiceId});}
 public async Task<IActionResult> OnPostVoidAsync(int invoiceId){try{await payments.Void(User,invoiceId);Notice="Invoice voided.";}catch(RuleException ex){Error=ex.Message;}return RedirectToPage(new{invoice=invoiceId});}
}
