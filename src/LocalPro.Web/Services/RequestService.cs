using System.Security.Claims;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Services;
public record ServiceRequestInput(int CategoryId,string Description,string Address,string City,string When,string PaymentPreference,string? PhotoBase64=null,string? PhotoType=null);
public class RequestService(AppDbContext db,IWebHostEnvironment env){
 public IQueryable<ServiceRequest> Query=>db.ServiceRequests.Include(r=>r.Category).Include(r=>r.Professional).ThenInclude(p=>p!.Category).Include(r=>r.Events);
 static string User(ClaimsPrincipal u)=>u.FindFirstValue(ClaimTypes.NameIdentifier)!;
 public async Task<List<ServiceRequest>> List(ClaimsPrincipal user){var id=User(user);return await Query.AsNoTracking().Where(r=>r.CustomerId==id||r.Professional!=null&&r.Professional.UserId==id).OrderByDescending(r=>r.CreatedUtc).Take(100).ToListAsync();}
 public async Task<ServiceRequest> Get(ClaimsPrincipal user,int id){var uid=User(user);return await Query.AsNoTracking().SingleOrDefaultAsync(r=>r.Id==id&&(r.CustomerId==uid||r.Professional!=null&&r.Professional.UserId==uid||user.IsInRole("Admin")))??throw new RuleException("Dalabka lama helin ama ma lihid oggolaansho.");}
 public async Task<ServiceRequest> Create(ClaimsPrincipal user,ServiceRequestInput input){
 var c=await db.Categories.SingleOrDefaultAsync(c=>c.Id==input.CategoryId&&c.Active)??throw new RuleException("Dooro adeeg sax ah.");
 if(string.IsNullOrWhiteSpace(input.Description)||input.Description.Length>2000||string.IsNullOrWhiteSpace(input.Address)||input.Address.Length>300||string.IsNullOrWhiteSpace(input.City)||input.City.Length>80)throw new RuleException("Buuxi sharaxaadda, magaalada iyo cinwaanka.");
 if(!new[]{"Now","Today","Tomorrow"}.Contains(input.When)||!new[]{"MobileMoney","Cash"}.Contains(input.PaymentPreference))throw new RuleException("Dooro waqtiga iyo habka lacag bixinta.");
 var local=DateTime.UtcNow.AddHours(3);var date=DateTime.SpecifyKind(local.Date.AddDays(input.When=="Tomorrow"?1:0).AddHours(-3),DateTimeKind.Utc);
 var r=new ServiceRequest{CustomerId=User(user),CategoryId=c.Id,Description=input.Description.Trim(),Address=input.Address.Trim(),City=input.City.Trim(),When=input.When,PaymentPreference=input.PaymentPreference,VisitFee=c.VisitFee,RequestedDateUtc=date};
 byte[]? photo=null;
 if(input.PhotoBase64!=null){try{photo=Convert.FromBase64String(input.PhotoBase64);}catch(FormatException){throw new RuleException("Sawirka lama akhrin karo.");}if(photo.Length>3*1024*1024)throw new RuleException("Sawirku waa inuu ka yar yahay 3 MB.");
 bool jpeg=photo.Length>3&&photo[0]==255&&photo[1]==216&&photo[2]==255;bool png=photo.Length>8&&photo.Take(8).SequenceEqual(new byte[]{137,80,78,71,13,10,26,10});
 if(!jpeg&&!png)throw new RuleException("Isticmaal sawir PNG ama JPEG ah.");r.PhotoType=png?"image/png":"image/jpeg";r.PhotoFile=Guid.NewGuid().ToString("N")+(png?".png":".jpg");
 }
 r.Events.Add(new(){ActorId=r.CustomerId,Status=ServiceRequestStatus.Received});db.Add(r);
 var admins=await(from ur in db.UserRoles join role in db.Roles on ur.RoleId equals role.Id where role.Name=="Admin" select ur.UserId).ToListAsync();
 foreach(var id in admins)db.Notifications.Add(new(){UserId=id,Text="Dalab adeeg cusub ayaa yimid.",Link="/Dispatch"});
 if(photo!=null){Directory.CreateDirectory(PhotoDirectory);await File.WriteAllBytesAsync(Path.Combine(PhotoDirectory,r.PhotoFile!),photo);}
 try{await db.SaveChangesAsync();}catch{if(r.PhotoFile!=null)File.Delete(Path.Combine(PhotoDirectory,r.PhotoFile));throw;}return r;
 }
 public string PhotoDirectory=>Path.Combine(env.ContentRootPath,"App_Data","request-photos");
 public async Task<(byte[] Bytes,string Type)> Photo(ClaimsPrincipal user,int id){var r=await Get(user,id);if(r.PhotoFile==null||!File.Exists(Path.Combine(PhotoDirectory,r.PhotoFile)))throw new RuleException("Dalabkani sawir ma leh.");return(await File.ReadAllBytesAsync(Path.Combine(PhotoDirectory,r.PhotoFile)),r.PhotoType!);}
 public async Task Edit(ClaimsPrincipal user,int id,ServiceRequestInput input){
 await using var tx=await db.Database.BeginTransactionAsync();
 var request=(await db.ServiceRequests.FromSqlInterpolated($"SELECT * FROM ServiceRequests WHERE Id = {id} FOR UPDATE").ToListAsync()).SingleOrDefault();
 if(request==null||request.CustomerId!=User(user)||request.Status!=ServiceRequestStatus.Received&&request.Status!=ServiceRequestStatus.Assigned)throw new RuleException("Dalabkan lama beddeli karo hadda.");
 if(input.CategoryId!=request.CategoryId||string.IsNullOrWhiteSpace(input.Description)||input.Description.Length>2000||string.IsNullOrWhiteSpace(input.Address)||input.Address.Length>300||string.IsNullOrWhiteSpace(input.City)||input.City.Length>80||!new[]{"Now","Today","Tomorrow"}.Contains(input.When)||!new[]{"MobileMoney","Cash"}.Contains(input.PaymentPreference))throw new RuleException("Hubi faahfaahinta dalabka.");
 request.Description=input.Description.Trim();request.Address=input.Address.Trim();request.City=input.City.Trim();request.When=input.When;request.PaymentPreference=input.PaymentPreference;request.RequestedDateUtc=DateTime.SpecifyKind(DateTime.UtcNow.AddHours(3).Date.AddDays(input.When=="Tomorrow"?1:0).AddHours(-3),DateTimeKind.Utc);request.UpdatedUtc=DateTime.UtcNow;
 db.AuditEvents.Add(new(){ActorId=User(user),Action=$"Service request {id}: edited"});
 if(request.ProfessionalId.HasValue){var p=await db.Professionals.FindAsync(request.ProfessionalId);if(p!=null)db.Notifications.Add(new(){UserId=p.UserId,Text=$"Faahfaahinta dalab #{id} waa la beddelay.",Link=$"/Requests/Track/{id}"});}
 await db.SaveChangesAsync();await tx.CommitAsync();
 }
 public async Task Change(ClaimsPrincipal user,int id,string action,int? professionalId=null){
 await using var tx=await db.Database.BeginTransactionAsync();
 var r=(await db.ServiceRequests.FromSqlInterpolated($"SELECT * FROM ServiceRequests WHERE Id = {id} FOR UPDATE").ToListAsync()).SingleOrDefault()??throw new RuleException("Dalabka lama helin.");
 var uid=User(user);var admin=user.IsInRole("Admin");var pro=r.ProfessionalId.HasValue?await db.Professionals.FindAsync(r.ProfessionalId):null;var owner=pro?.UserId==uid;
 if(action=="assign"&&admin&&(r.Status==ServiceRequestStatus.Received||r.Status==ServiceRequestStatus.Assigned)){
 var assigned=await db.Professionals.SingleOrDefaultAsync(p=>p.Id==professionalId&&p.Approved&&p.AcceptingRequests&&p.CategoryId==r.CategoryId)??throw new RuleException("Dooro xirfadle la oggolaaday oo adeeggan bixiya.");
 if(pro!=null&&pro.Id!=assigned.Id)db.Notifications.Add(new(){UserId=pro.UserId,Text=$"Dalab #{id} waxaa loo wareejiyay xirfadle kale.",Link="/Requests"});
 if(assigned.UserId==r.CustomerId)throw new RuleException("Qofku dalabkiisa iskuma qaban karo.");r.ProfessionalId=assigned.Id;r.Status=ServiceRequestStatus.Assigned;
 db.Notifications.Add(new(){UserId=assigned.UserId,Text=$"Dalab #{id} ayaa laguu xilsaaray.",Link=$"/Requests/Track/{id}"});
 }else if(action=="cancel"&&(uid==r.CustomerId||admin)&&(r.Status==ServiceRequestStatus.Received||r.Status==ServiceRequestStatus.Assigned||r.Status==ServiceRequestStatus.OnTheWay))r.Status=ServiceRequestStatus.Cancelled;
 else if((owner||admin)&&action=="depart"&&r.Status==ServiceRequestStatus.Assigned)r.Status=ServiceRequestStatus.OnTheWay;
 else if((owner||admin)&&action=="start"&&r.Status==ServiceRequestStatus.OnTheWay)r.Status=ServiceRequestStatus.InProgress;
 else if((owner||admin)&&action=="complete"&&r.Status==ServiceRequestStatus.InProgress)r.Status=ServiceRequestStatus.Completed;
 else throw new RuleException("Tallaabadan lama oggola hadda.");
 r.UpdatedUtc=DateTime.UtcNow;db.ServiceRequestEvents.Add(new(){ServiceRequestId=id,ActorId=uid,Status=r.Status});db.AuditEvents.Add(new(){ActorId=uid,Action=$"Service request {id}: {action}"});
 db.Notifications.Add(new(){UserId=r.CustomerId,Text=$"Dalab #{id}: {ServiceCatalog.Status(r.Status)}.",Link=$"/Requests/Track/{id}"});
 if(action=="cancel"&&pro!=null)db.Notifications.Add(new(){UserId=pro.UserId,Text=$"Dalab #{id} waa la joojiyay.",Link=$"/Requests/Track/{id}"});
 await db.SaveChangesAsync();await tx.CommitAsync();
 }
 public static object Dto(ServiceRequest r,string uid)=>new{r.Id,r.CategoryId,category=r.Category.Name,icon=r.Category.Icon,r.Description,r.Address,r.City,r.When,r.PaymentPreference,r.VisitFee,status=r.Status.ToString(),statusLabel=ServiceCatalog.Status(r.Status),r.CreatedUtc,r.UpdatedUtc,r.ProfessionalId,professional=r.Professional?.Name,phone=r.Status==ServiceRequestStatus.Cancelled?null:r.Professional?.Phone,canCommunicate=r.ProfessionalId.HasValue&&r.Status!=ServiceRequestStatus.Received&&r.Status!=ServiceRequestStatus.Cancelled,r.CustomerId,isProfessional=r.Professional?.UserId==uid,hasPhoto=r.PhotoFile!=null,events=r.Events.OrderBy(e=>e.CreatedUtc).ThenBy(e=>e.Id).Select(e=>new{status=e.Status.ToString(),label=ServiceCatalog.Status(e.Status),e.CreatedUtc})};
}
