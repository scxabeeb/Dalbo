using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;
namespace LocalPro.Web.Domain;
public class AppUser : IdentityUser { [MaxLength(100)] public string DisplayName {get;set;} = ""; }
public class Category { public int Id {get;set;} [MaxLength(80)] public string Name {get;set;}=""; [MaxLength(20)] public string Icon {get;set;}=""; }
public class Professional {
 public int Id {get;set;} public string UserId {get;set;}=""; public AppUser User {get;set;}=null!;
 public int CategoryId {get;set;} public Category Category {get;set;}=null!;
 [MaxLength(100)] public string Name {get;set;}="";
 [MaxLength(100)] public string City {get;set;}="Mogadishu";
 [MaxLength(100)] public string Neighborhood {get;set;}="";
 [MaxLength(2000)] public string Bio {get;set;}="";
 [MaxLength(30)] public string Phone {get;set;}="";
 public decimal HourlyRate {get;set;} public int YearsExperience {get;set;}
 public bool Approved {get;set;} public bool AcceptingRequests {get;set;}=true;
 public int StartHour {get;set;}=8; public int EndHour {get;set;}=18;
 public List<Review> Reviews {get;set;}=[];
}
public enum AppointmentStatus { Requested, Confirmed, InProgress, Completed, Cancelled, Declined, Expired }
public class Appointment {
 public int Id {get;set;} public string CustomerId {get;set;}=""; public AppUser Customer {get;set;}=null!;
 public int ProfessionalId {get;set;} public Professional Professional {get;set;}=null!;
 public DateTime StartUtc {get;set;} public DateTime EndUtc {get;set;}
 public AppointmentStatus Status {get;set;}=AppointmentStatus.Requested;
 [MaxLength(2000)] public string Description {get;set;}="";
 [MaxLength(300)] public string Address {get;set;}="";
 public DateTime CreatedUtc {get;set;}=DateTime.UtcNow;
 public DateTime? ProposedStartUtc {get;set;} public string? ProposedById {get;set;}
}
public class Message { public int Id {get;set;} public string CustomerId {get;set;}=""; public int ProfessionalId {get;set;} public string SenderId {get;set;}=""; [MaxLength(2000)] public string Text {get;set;}=""; public DateTime CreatedUtc {get;set;}=DateTime.UtcNow; }
public class Review { public int Id {get;set;} public int AppointmentId {get;set;} public Appointment Appointment {get;set;}=null!; public int ProfessionalId {get;set;} public Professional Professional {get;set;}=null!; public int Rating {get;set;} [MaxLength(1000)] public string Text {get;set;}=""; }
public class AuditEvent { public int Id {get;set;} public string ActorId {get;set;}=""; public string Action {get;set;}=""; public DateTime CreatedUtc {get;set;}=DateTime.UtcNow; }

public class Notification { public int Id {get;set;} public string UserId {get;set;}=""; [MaxLength(300)] public string Text {get;set;}=""; public string Link {get;set;}="/Appointments"; public bool Read {get;set;} public DateTime CreatedUtc {get;set;}=DateTime.UtcNow; }
public class Favorite { public int Id {get;set;} public string UserId {get;set;}=""; public int ProfessionalId {get;set;} }
public class UserBlock { public int Id {get;set;} public string UserId {get;set;}=""; public string BlockedUserId {get;set;}=""; }
public class UserReport { public int Id {get;set;} public string UserId {get;set;}=""; public int ProfessionalId {get;set;} [MaxLength(2000)] public string Reason {get;set;}=""; public bool Resolved {get;set;} public DateTime CreatedUtc {get;set;}=DateTime.UtcNow; }
