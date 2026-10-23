using System.Data;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Services;
public class RuleException(string message):Exception(message);
public class Marketplace(AppDbContext db) {
 public static DateTime ToUtc(DateTime local)=>DateTime.SpecifyKind(local,DateTimeKind.Unspecified).AddHours(-3);
 public static DateTime ToLocal(DateTime utc)=>DateTime.SpecifyKind(utc,DateTimeKind.Utc).AddHours(3);
 public async Task<List<Professional>> Search(string? q=null,int? category=null,string? city=null,bool available=false){
 var query=db.Professionals.AsNoTracking().Include(x=>x.Category).Include(x=>x.Reviews).Where(x=>x.Approved);
 if(!string.IsNullOrWhiteSpace(q))query=query.Where(x=>x.Name.Contains(q)||x.Bio.Contains(q)||x.Category.Name.Contains(q));
 if(category.HasValue)query=query.Where(x=>x.CategoryId==category);
 if(!string.IsNullOrWhiteSpace(city))query=query.Where(x=>x.City.Contains(city)||x.Neighborhood.Contains(city));
 if(available)query=query.Where(x=>x.AcceptingRequests);
 return await query.OrderBy(x=>x.Name).ToListAsync(); }
 public async Task<Professional> Profile(int id)=>await db.Professionals.Include(x=>x.Category).Include(x=>x.Reviews).SingleOrDefaultAsync(x=>x.Id==id&&x.Approved)??throw new RuleException("Professional is unavailable.");
 static void ValidateTime(Professional p,DateTime start){var local=ToLocal(start); if(start.Kind!=DateTimeKind.Utc||start<DateTime.UtcNow.AddMinutes(15)||start>DateTime.UtcNow.AddDays(90)||local.Minute!=0||local.Second!=0||local.Hour<p.StartHour||local.Hour>=p.EndHour)throw new RuleException("Choose a whole-hour appointment within working hours, 15 minutes to 90 days ahead.");}
 public async Task<Appointment> Book(string user,int pro,DateTime start,string description,string address){
 var p=await Profile(pro); if(p.UserId==user)throw new RuleException("You cannot book your own services."); if(!p.AcceptingRequests)throw new RuleException("This professional is not accepting requests.");
 ValidateTime(p,start);if(string.IsNullOrWhiteSpace(description)||description.Length>2000||string.IsNullOrWhiteSpace(address)||address.Length>300)throw new RuleException("Enter an issue description and service address within the character limits.");
 if(await db.Appointments.AnyAsync(a=>a.CustomerId==user&&a.ProfessionalId==pro&&a.StartUtc==start&&a.Status==AppointmentStatus.Requested))throw new RuleException("You already requested this appointment.");
 if(await db.Appointments.AnyAsync(a=>a.ProfessionalId==pro&&(a.Status==AppointmentStatus.Confirmed||a.Status==AppointmentStatus.InProgress)&&a.StartUtc<start.AddHours(1)&&a.EndUtc>start))throw new RuleException("This time has already been booked.");
 var a=new Appointment{CustomerId=user,ProfessionalId=pro,StartUtc=start,EndUtc=start.AddHours(1),Description=description.Trim(),Address=address.Trim()};db.Add(a);db.Notifications.Add(new(){UserId=p.UserId,Text=$"New appointment request for {ToLocal(start):dd MMM HH:mm} EAT."});await db.SaveChangesAsync();return a; }
 public Task<List<Appointment>> Appointments(string user)=>db.Appointments.AsNoTracking().Include(x=>x.Professional).ThenInclude(x=>x.Category).Include(x=>x.Customer).Where(x=>x.CustomerId==user||x.Professional.UserId==user).OrderByDescending(x=>x.StartUtc).ToListAsync();
 public async Task Transition(string user,int id,string action,DateTime? proposed=null){
 await using var tx=await db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
 var initial=await db.Appointments.AsNoTracking().SingleOrDefaultAsync(x=>x.Id==id)??throw new RuleException("Appointment not found.");
 // A row lock serializes all confirmations for the same professional, across server instances.
 var p=await db.Professionals.FromSqlInterpolated($"SELECT * FROM Professionals WHERE Id = {initial.ProfessionalId} FOR UPDATE").SingleAsync();
 var a=await db.Appointments.SingleAsync(x=>x.Id==id);bool owner=p.UserId==user,customer=a.CustomerId==user;
 if(!owner&&!customer)throw new RuleException("You cannot access this appointment.");
 if(action=="confirm"&&owner&&a.Status==AppointmentStatus.Requested){
 if(!p.Approved||!p.AcceptingRequests)throw new RuleException("This profile is not accepting bookings.");ValidateTime(p,a.StartUtc);
 await EnsureFree(a,a.StartUtc);a.Status=AppointmentStatus.Confirmed;
 var conflicts=await db.Appointments.Where(x=>x.Id!=id&&x.ProfessionalId==p.Id&&x.Status==AppointmentStatus.Requested&&x.StartUtc<a.EndUtc&&x.EndUtc>a.StartUtc).ToListAsync();foreach(var c in conflicts)c.Status=AppointmentStatus.Declined;
 }else if(action=="decline"&&owner&&a.Status==AppointmentStatus.Requested)a.Status=AppointmentStatus.Declined;
 else if(action=="cancel"&&(a.Status==AppointmentStatus.Requested||a.Status==AppointmentStatus.Confirmed)){if(a.StartUtc<=DateTime.UtcNow)throw new RuleException("Past appointments cannot be cancelled.");a.Status=AppointmentStatus.Cancelled;}
 else if(action=="start"&&owner&&a.Status==AppointmentStatus.Confirmed){if(DateTime.UtcNow<a.StartUtc.AddMinutes(-15))throw new RuleException("Work can start 15 minutes before the appointment.");a.Status=AppointmentStatus.InProgress;}
 else if(action=="complete"&&owner&&a.Status==AppointmentStatus.InProgress)a.Status=AppointmentStatus.Completed;
 else if(action=="reschedule"&&a.Status==AppointmentStatus.Confirmed&&proposed.HasValue){ValidateTime(p,proposed.Value);a.ProposedStartUtc=proposed;a.ProposedById=user;}
 else if(action=="accept-time"&&a.Status==AppointmentStatus.Confirmed&&a.ProposedStartUtc.HasValue&&a.ProposedById!=user){ValidateTime(p,a.ProposedStartUtc.Value);await EnsureFree(a,a.ProposedStartUtc.Value);a.StartUtc=a.ProposedStartUtc.Value;a.EndUtc=a.StartUtc.AddHours(1);a.ProposedStartUtc=null;a.ProposedById=null;}
 else throw new RuleException("This action is not allowed for the current appointment status.");
 db.Notifications.Add(new(){UserId=owner?a.CustomerId:p.UserId,Text=$"Appointment #{id}: {action}."});
 db.AuditEvents.Add(new(){ActorId=user,Action=$"Appointment {id}: {action}"});await db.SaveChangesAsync();await tx.CommitAsync(); }
 async Task EnsureFree(Appointment a,DateTime start){if(await db.Appointments.AnyAsync(x=>x.Id!=a.Id&&x.ProfessionalId==a.ProfessionalId&&(x.Status==AppointmentStatus.Confirmed||x.Status==AppointmentStatus.InProgress)&&x.StartUtc<start.AddHours(1)&&x.EndUtc>start))throw new RuleException("This time is already confirmed. Choose another hour.");}
 public async Task<List<Message>> Conversation(string user,int pro,string? customer){var p=await db.Professionals.FindAsync(pro)??throw new RuleException("Professional not found.");var c=p.UserId==user?customer:user;if(string.IsNullOrEmpty(c)||c==p.UserId)throw new RuleException("Choose a customer conversation.");if(await db.Blocks.AnyAsync(b=>(b.UserId==p.UserId&&b.BlockedUserId==c)||(b.UserId==c&&b.BlockedUserId==p.UserId)))throw new RuleException("This conversation is blocked.");if(p.UserId==user&&!await db.Messages.AnyAsync(m=>m.ProfessionalId==pro&&m.CustomerId==c)&&!await db.Appointments.AnyAsync(a=>a.ProfessionalId==pro&&a.CustomerId==c))throw new RuleException("No customer conversation exists.");if(p.UserId!=user&&!p.Approved)throw new RuleException("Professional unavailable.");return await db.Messages.AsNoTracking().Where(x=>x.ProfessionalId==pro&&x.CustomerId==c).OrderBy(x=>x.CreatedUtc).Take(500).ToListAsync();}
 public async Task Send(string user,int pro,string? customer,string text){await Conversation(user,pro,customer);var p=await db.Professionals.FindAsync(pro);var c=p!.UserId==user?customer!:user;if(string.IsNullOrWhiteSpace(text)||text.Length>2000)throw new RuleException("Messages must contain 1–2000 characters.");db.Messages.Add(new(){ProfessionalId=pro,CustomerId=c,SenderId=user,Text=text.Trim()});db.Notifications.Add(new(){UserId=p.UserId==user?c:p.UserId,Text="You have a new message.",Link=$"/Messages?pro={pro}&customer={Uri.EscapeDataString(c)}"});await db.SaveChangesAsync();}
 public async Task Review(string user,int appointment,int rating,string text){var a=await db.Appointments.SingleOrDefaultAsync(x=>x.Id==appointment&&x.CustomerId==user&&x.Status==AppointmentStatus.Completed)??throw new RuleException("Only your completed appointments can be reviewed.");if(rating<1||rating>5||text==null||text.Length>1000)throw new RuleException("Enter a rating from 1 to 5 and up to 1000 characters.");if(await db.Reviews.AnyAsync(x=>x.AppointmentId==appointment))throw new RuleException("You already reviewed this appointment.");db.Reviews.Add(new(){AppointmentId=appointment,ProfessionalId=a.ProfessionalId,Rating=rating,Text=text});await db.SaveChangesAsync();}
}
