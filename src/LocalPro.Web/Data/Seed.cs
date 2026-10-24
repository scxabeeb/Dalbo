using LocalPro.Web.Domain;
using LocalPro.Web.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Data;
public static class Seed {
 public static async Task Run(IServiceProvider services,bool demo,string? password){
 var db=services.GetRequiredService<AppDbContext>();await db.Database.MigrateAsync();
 if(!await db.Categories.AnyAsync()){db.Categories.AddRange(new Category{Name="Electrical",Icon="ϟ"},new Category{Name="Plumbing",Icon="◉"},new Category{Name="Air conditioning",Icon="❄"},new Category{Name="Refrigeration",Icon="▤"});await db.SaveChangesAsync();}
 if(!await db.SiteSettings.AnyAsync()){await ServiceCatalog.Sync(db);db.SiteSettings.Add(new());await db.SaveChangesAsync();}
 var roles=services.GetRequiredService<RoleManager<IdentityRole>>();if(!await roles.RoleExistsAsync("Admin"))await roles.CreateAsync(new("Admin"));
 var users=services.GetRequiredService<UserManager<AppUser>>();
 if(!demo)return;if(string.IsNullOrWhiteSpace(password))throw new InvalidOperationException("Set DemoPassword via environment variable when SeedDemo=true.");
 async Task<AppUser> User(string email,string name){var u=await users.FindByEmailAsync(email);if(u!=null)return u;u=new(){UserName=email,Email=email,DisplayName=name};var result=await users.CreateAsync(u,password);if(!result.Succeeded)throw new InvalidOperationException(string.Join("; ",result.Errors.Select(e=>e.Description)));return u;}
 var admin=await User("admin@localpro.test","DANXALIYE Admin");await users.AddToRoleAsync(admin,"Admin");await User("customer@localpro.test","Amina Hassan");
 string[] names=["Ahmed Mohamed","Fatima Ali","Yusuf Hassan","Khadija Omar","Abdirahman Nur","Maryan Ahmed"];
 string[] areas=["Hodan","Waberi","Hamar Weyne","Wadajir","Hodan","Abdiaziz"];
 var cats=await db.Categories.Where(c=>c.Active).OrderBy(c=>c.Id).ToListAsync();
 for(var i=0;i<names.Length;i++){var u=await User($"pro{i+1}@localpro.test",names[i]);if(await db.Professionals.AnyAsync(p=>p.UserId==u.Id))continue;db.Professionals.Add(new(){UserId=u.Id,Name=names[i],CategoryId=cats[i%4].Id,Neighborhood=areas[i],HourlyRate=15+i*3,YearsExperience=4+i,Approved=true,Bio="Careful, reliable service for your home and business. I explain the work and agree on the price before getting started.",Phone="",StartHour=8,EndHour=18});}await db.SaveChangesAsync();
 }
}
