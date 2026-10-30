using LocalPro.Web.Domain;
using LocalPro.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LocalPro.Web.Pages.Payments;
[Authorize]
public class InvoiceModel(PaymentService payments):PageModel {
 public ServiceInvoice? Invoice{get;set;}
 public async Task<IActionResult> OnGetAsync(int id){Response.Headers.CacheControl="private, no-store";try{Invoice=await payments.Get(User,id);return Page();}catch(RuleException){return NotFound();}}
}
