using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Services;

// Local maintenance command only. Import data belongs in ignored App_Data, never in source control.
public static class ProfessionalImport {
 public record Entry(string Name,string Category,string Phone,string City,string? Notes);
 public static async Task<(int Added,int Skipped)> Run(IServiceProvider services,string path){
  var entries=JsonSerializer.Deserialize<List<Entry>>(await File.ReadAllTextAsync(path),new JsonSerializerOptions{PropertyNameCaseInsensitive=true})??throw new InvalidOperationException("No import rows found.");
  if(entries.Count==0||entries.Count>1000)throw new InvalidOperationException("Import requires 1–1000 rows.");
  var db=services.GetRequiredService<AppDbContext>();var users=services.GetRequiredService<UserManager<AppUser>>();
  var categories=await db.Categories.Where(c=>c.Active).ToListAsync();var existing=await db.Professionals.ToListAsync();
  var seen=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
  foreach(var e in entries){
   if(string.IsNullOrWhiteSpace(e.Name)||e.Name.Length>100||string.IsNullOrWhiteSpace(e.Phone)||e.Phone.Length>30||string.IsNullOrWhiteSpace(e.City)||e.City.Length>100||e.Notes?.Length>1500||!categories.Any(c=>c.Name==e.Category))throw new InvalidOperationException("Invalid name, phone, location or category in import.");
   if(!seen.Add(e.Category.Trim()+"|"+e.Phone.Trim()))throw new InvalidOperationException("Duplicate category/phone in import file.");
  }
  await using var transaction=await db.Database.BeginTransactionAsync();var added=0;var skipped=0;
  // These providers have no supplied email/password. The CLI exits before HTTP starts.
  // Temporarily allow email-less Identity accounts, and restore the normal registration policy afterward.
  var requireEmail=users.Options.User.RequireUniqueEmail;users.Options.User.RequireUniqueEmail=false;
  try{
   foreach(var e in entries){
    var category=categories.Single(c=>c.Name==e.Category);var phone=e.Phone.Trim();var name=e.Name.Trim();
    var matches=existing.Where(p=>p.CategoryId==category.Id&&(p.Phone==phone||p.Name.Equals(name,StringComparison.OrdinalIgnoreCase))).ToList();
    if(matches.Any(p=>p.Phone==phone&&p.Name.Equals(name,StringComparison.OrdinalIgnoreCase))){skipped++;continue;}
    if(matches.Count!=0)throw new InvalidOperationException("A conflicting professional already exists. No rows were imported; review the existing profile before retrying.");
    var account=new AppUser{UserName="provider-"+Guid.NewGuid().ToString("N"),DisplayName=name,PhoneNumber=phone};
    var result=await users.CreateAsync(account);if(!result.Succeeded)throw new InvalidOperationException("Unable to create provider account: "+string.Join("; ",result.Errors.Select(e=>e.Description)));
    var profile=new Professional{UserId=account.Id,CategoryId=category.Id,Name=name,Phone=phone,City=e.City.Trim(),Approved=true,AcceptingRequests=true,Bio=string.Join(" ",new[]{e.Notes,"Rates, experience and working hours must be confirmed with dispatch."}.Where(s=>!string.IsNullOrWhiteSpace(s)))};
    db.Professionals.Add(profile);existing.Add(profile);added++;
   }
   db.AuditEvents.Add(new(){ActorId="local-administrator",Action=$"Professional import: {added} added, {skipped} existing rows skipped. No login passwords or email addresses supplied."});
   await db.SaveChangesAsync();await transaction.CommitAsync();return(added,skipped);
  }finally{users.Options.User.RequireUniqueEmail=requireEmail;}
 }
}
