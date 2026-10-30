using System.Security.Claims;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Services;
public class PaymentService(AppDbContext db, ConfigurationService config) {
 public static readonly string[] Methods=["Cash","EVCPlus","ZAAD","Sahal","BankTransfer","Card"];
 public static string MethodLabel(string method)=>method switch{"EVCPlus"=>"EVC Plus","BankTransfer"=>"Bank transfer","Card"=>"Card (received externally)",_=>method};
 public IQueryable<ServiceInvoice> Query=>db.Set<ServiceInvoice>().Include(i=>i.Payments).Include(i=>i.ServiceRequest).ThenInclude(r=>r.Customer).Include(i=>i.ServiceRequest).ThenInclude(r=>r.Category);
 static string Admin(ClaimsPrincipal actor){if(!actor.IsInRole("Admin"))throw new RuleException("Administrator access is required.");return actor.FindFirstValue(ClaimTypes.NameIdentifier)!;}
 public async Task<ServiceInvoice?> Get(ClaimsPrincipal actor,int requestId){var uid=actor.FindFirstValue(ClaimTypes.NameIdentifier);if(uid==null||!await db.ServiceRequests.AnyAsync(r=>r.Id==requestId&&(actor.IsInRole("Admin")||r.CustomerId==uid)))throw new RuleException("Invoice not found.");return await Query.AsNoTracking().SingleOrDefaultAsync(i=>i.ServiceRequestId==requestId);}
 public async Task Create(ClaimsPrincipal actor,int requestId,decimal total,string? notes){var uid=Admin(actor);if(total<=0||total>10000000||decimal.Round(total,2)!=total||notes?.Length>1000)throw new RuleException("Enter a total above zero with at most two decimal places, and notes up to 1,000 characters.");
 await using var tx=await db.Database.BeginTransactionAsync();
 var request=await db.ServiceRequests.FromSqlInterpolated($"SELECT * FROM `ServiceRequests` WHERE `Id`={requestId} FOR UPDATE").SingleOrDefaultAsync();
 if(request==null||request.Status==ServiceRequestStatus.Cancelled)throw new RuleException("Choose an active service request.");
 if(await db.Set<ServiceInvoice>().AnyAsync(i=>i.ServiceRequestId==requestId))throw new RuleException("This request already has an invoice.");
 db.Add(new ServiceInvoice{ServiceRequestId=requestId,Total=total,Currency=(await config.Get()).Currency,Notes=notes?.Trim()??""});
 db.AuditEvents.Add(new(){ActorId=uid,Action=$"Created invoice for request {requestId}"});await db.SaveChangesAsync();await tx.CommitAsync();}
 public async Task Record(ClaimsPrincipal actor,int invoiceId,decimal amount,string? method,string? reference,string? key){var uid=Admin(actor);if(amount<=0||amount>10000000||decimal.Round(amount,2)!=amount||!Methods.Contains(method)||reference?.Length>100||!Guid.TryParse(key,out var parsed))throw new RuleException("Enter a valid amount, payment method, reference and submission key.");if(method!="Cash"&&string.IsNullOrWhiteSpace(reference))throw new RuleException("Enter the transaction reference for this payment.");
 await using var tx=await db.Database.BeginTransactionAsync();
 var invoice=await db.Set<ServiceInvoice>().FromSqlInterpolated($"SELECT * FROM `ServiceInvoice` WHERE `Id`={invoiceId} FOR UPDATE").SingleOrDefaultAsync();if(invoice==null)throw new RuleException("Invoice not found.");
 var canonical=parsed.ToString();var previous=await db.Set<ServicePayment>().SingleOrDefaultAsync(p=>p.IdempotencyKey==canonical);
 if(previous!=null){if(previous.ServiceInvoiceId!=invoiceId||previous.Amount!=amount||previous.Method!=method||previous.Reference!=(reference?.Trim()??""))throw new RuleException("This submission key was already used for a different payment.");return;}
 var paid=await db.Set<ServicePayment>().Where(p=>p.ServiceInvoiceId==invoiceId).SumAsync(p=>(decimal?)p.Amount)??0;
 if(invoice.Voided||amount>invoice.Total-paid)throw new RuleException("Payment exceeds the outstanding balance or the invoice is void.");
 db.Add(new ServicePayment{ServiceInvoiceId=invoiceId,Amount=amount,Method=method!,Reference=reference?.Trim()??"",IdempotencyKey=canonical,RecordedById=uid});db.AuditEvents.Add(new(){ActorId=uid,Action=$"Recorded {method} payment on invoice {invoiceId}"});await db.SaveChangesAsync();await tx.CommitAsync();}
 public async Task Void(ClaimsPrincipal actor,int invoiceId){var uid=Admin(actor);await using var tx=await db.Database.BeginTransactionAsync();var invoice=await db.Set<ServiceInvoice>().FromSqlInterpolated($"SELECT * FROM `ServiceInvoice` WHERE `Id`={invoiceId} FOR UPDATE").SingleOrDefaultAsync();if(invoice==null)throw new RuleException("Invoice not found.");if(await db.Set<ServicePayment>().AnyAsync(p=>p.ServiceInvoiceId==invoiceId))throw new RuleException("An invoice with recorded payments cannot be voided.");invoice.Voided=true;db.AuditEvents.Add(new(){ActorId=uid,Action=$"Voided invoice {invoiceId}"});await db.SaveChangesAsync();await tx.CommitAsync();}
 public static object Dto(ServiceInvoice invoice)=>new{invoice.Id,invoice.ServiceRequestId,invoice.Total,invoice.Currency,invoice.Notes,invoice.CreatedUtc,invoice.Paid,invoice.Balance,invoice.Status,payments=invoice.Payments.OrderByDescending(p=>p.ReceivedUtc).Select(p=>new{p.Id,p.Amount,p.Method,p.Reference,p.ReceivedUtc})};
}
