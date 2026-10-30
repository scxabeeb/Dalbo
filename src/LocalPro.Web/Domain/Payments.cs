using System.ComponentModel.DataAnnotations;
namespace LocalPro.Web.Domain;
public class ServiceInvoice {
 public int Id {get;set;}
 public int ServiceRequestId {get;set;} public ServiceRequest ServiceRequest {get;set;}=null!;
 public decimal Total {get;set;}
 [MaxLength(3)] public string Currency {get;set;}="USD";
 [MaxLength(1000)] public string Notes {get;set;}="";
 public bool Voided {get;set;}
 public DateTime CreatedUtc {get;set;}=DateTime.UtcNow;
 public List<ServicePayment> Payments {get;set;}=[];
 public decimal Paid=>Payments.Sum(p=>p.Amount);
 public decimal Balance=>Voided?0:Total-Paid;
 public string Status=>Voided?"Void":Paid>=Total?"Paid":Paid>0?"Partially paid":"Unpaid";
}
public class ServicePayment {
 public int Id {get;set;} public int ServiceInvoiceId {get;set;} public ServiceInvoice ServiceInvoice {get;set;}=null!;
 public decimal Amount {get;set;}
 [MaxLength(20)] public string Method {get;set;}="Cash";
 [MaxLength(100)] public string Reference {get;set;}="";
 [MaxLength(36)] public string IdempotencyKey {get;set;}="";
 [MaxLength(255)] public string RecordedById {get;set;}="";
 public DateTime ReceivedUtc {get;set;}=DateTime.UtcNow;
}
