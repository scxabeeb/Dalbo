using LocalPro.Web.Domain;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Data;
public class AppDbContext(DbContextOptions<AppDbContext> options):IdentityDbContext<AppUser>(options) {
 public DbSet<Category> Categories=>Set<Category>(); public DbSet<Professional> Professionals=>Set<Professional>();
 public DbSet<Appointment> Appointments=>Set<Appointment>(); public DbSet<Message> Messages=>Set<Message>(); public DbSet<Review> Reviews=>Set<Review>(); public DbSet<AuditEvent> AuditEvents=>Set<AuditEvent>();
 public DbSet<Notification> Notifications=>Set<Notification>();public DbSet<Favorite> Favorites=>Set<Favorite>();public DbSet<UserReport> Reports=>Set<UserReport>();public DbSet<UserBlock> Blocks=>Set<UserBlock>();
 public DbSet<ServiceRequest> ServiceRequests=>Set<ServiceRequest>();public DbSet<ServiceRequestEvent> ServiceRequestEvents=>Set<ServiceRequestEvent>();
 public DbSet<SiteSettings> SiteSettings=>Set<SiteSettings>(); public DbSet<Product> Products=>Set<Product>();
 protected override void OnModelCreating(ModelBuilder b){base.OnModelCreating(b);
 b.Entity<ServiceInvoice>().Property(i=>i.Total).HasPrecision(12,2);
 b.Entity<ServiceInvoice>().HasIndex(i=>i.ServiceRequestId).IsUnique();
 b.Entity<ServiceInvoice>().Ignore(i=>i.Paid).Ignore(i=>i.Balance).Ignore(i=>i.Status);
 b.Entity<ServiceInvoice>().HasOne(i=>i.ServiceRequest).WithMany().HasForeignKey(i=>i.ServiceRequestId).OnDelete(DeleteBehavior.Restrict);
 b.Entity<ServicePayment>().Property(p=>p.Amount).HasPrecision(12,2);
 b.Entity<ServicePayment>().HasIndex(p=>p.IdempotencyKey).IsUnique();
 b.Entity<ServicePayment>().HasOne(p=>p.ServiceInvoice).WithMany(i=>i.Payments).HasForeignKey(p=>p.ServiceInvoiceId).OnDelete(DeleteBehavior.Restrict);
 b.Entity<Product>().Property(p=>p.Price).HasPrecision(12,2);
 b.Entity<Category>().Property(c=>c.VisitFee).HasPrecision(10,2);
 b.Entity<ServiceRequest>().Property(c=>c.VisitFee).HasPrecision(10,2);
 b.Entity<ServiceRequest>().HasOne(r=>r.Customer).WithMany().HasForeignKey(r=>r.CustomerId).OnDelete(DeleteBehavior.Restrict);
 b.Entity<ServiceRequest>().HasOne(r=>r.Professional).WithMany().HasForeignKey(r=>r.ProfessionalId).OnDelete(DeleteBehavior.Restrict);
 b.Entity<ServiceRequest>().HasIndex(r=>new{r.CustomerId,r.CreatedUtc});
 b.Entity<Favorite>().HasIndex(x=>new{x.UserId,x.ProfessionalId}).IsUnique();b.Entity<UserBlock>().HasIndex(x=>new{x.UserId,x.BlockedUserId}).IsUnique();b.Entity<Notification>().HasIndex(x=>new{x.UserId,x.CreatedUtc});
 b.Entity<Professional>().HasIndex(x=>x.UserId).IsUnique(); b.Entity<Professional>().Property(x=>x.HourlyRate).HasPrecision(10,2);
 b.Entity<Professional>().HasOne(x=>x.User).WithMany().HasForeignKey(x=>x.UserId).OnDelete(DeleteBehavior.Restrict);
 b.Entity<Appointment>().HasOne(x=>x.Customer).WithMany().HasForeignKey(x=>x.CustomerId).OnDelete(DeleteBehavior.Restrict);
 b.Entity<Appointment>().HasIndex(x=>new{x.ProfessionalId,x.StartUtc,x.EndUtc});
 b.Entity<Review>().HasIndex(x=>x.AppointmentId).IsUnique();
 b.Entity<Review>().HasOne(x=>x.Professional).WithMany(x=>x.Reviews).HasForeignKey(x=>x.ProfessionalId).OnDelete(DeleteBehavior.Restrict);
 foreach(var entity in b.Model.GetEntityTypes()) foreach(var property in entity.GetProperties()) {
 if(property.ClrType==typeof(DateTime)||property.ClrType==typeof(DateTime?)) property.SetValueConverter(new Microsoft.EntityFrameworkCore.Storage.ValueConversion.ValueConverter<DateTime,DateTime>(v=>v,v=>DateTime.SpecifyKind(v,DateTimeKind.Utc)));
 }
 b.Entity<Message>().HasIndex(x=>new{x.ProfessionalId,x.CustomerId,x.CreatedUtc});
 }
}
