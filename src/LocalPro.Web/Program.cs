using System.Security.Claims;
using System.Threading.RateLimiting;
using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using LocalPro.Web.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
var builder=WebApplication.CreateBuilder(args);
if(builder.Environment.IsDevelopment())builder.Configuration.AddJsonFile("appsettings.Local.json",optional:true,reloadOnChange:false).AddEnvironmentVariables().AddCommandLine(args);
builder.Services.AddRazorPages(o=>{o.Conventions.AuthorizeFolder("/Account");o.Conventions.AllowAnonymousToPage("/Account/Login");o.Conventions.AllowAnonymousToPage("/Account/Register");});
builder.Services.AddDbContext<AppDbContext>(o=>o.UseMySql(builder.Configuration.GetConnectionString("Default"),new MySqlServerVersion(new Version(8,4,0))));
builder.Services.AddIdentityApiEndpoints<AppUser>(o=>{o.Password.RequiredLength=10;o.User.RequireUniqueEmail=true;o.Lockout.MaxFailedAccessAttempts=5;}).AddRoles<IdentityRole>().AddEntityFrameworkStores<AppDbContext>();
builder.Services.AddAuthentication(o=>{o.DefaultChallengeScheme=IdentityConstants.ApplicationScheme;o.DefaultForbidScheme=IdentityConstants.ApplicationScheme;});
builder.Services.ConfigureApplicationCookie(o=>{o.LoginPath="/Account/Login";o.Cookie.HttpOnly=true;o.Cookie.SameSite=SameSiteMode.Lax;o.AccessDeniedPath="/Denied";});
builder.Services.AddScoped<Marketplace>();builder.Services.AddScoped<RequestService>();
builder.WebHost.ConfigureKestrel(o=>o.Limits.MaxRequestBodySize=5*1024*1024);
builder.Services.AddRateLimiter(o=>{o.RejectionStatusCode=429;o.AddPolicy("auth",ctx=>RateLimitPartition.GetFixedWindowLimiter(ctx.Connection.RemoteIpAddress?.ToString()??"unknown",_=>new(){PermitLimit=20,Window=TimeSpan.FromMinutes(1),QueueLimit=0}));});
var app=builder.Build();
if(!app.Environment.IsDevelopment()){app.UseExceptionHandler("/Error");app.UseHsts();app.UseHttpsRedirection();}
app.Use(async(ctx,next)=>{ctx.Response.Headers["X-Content-Type-Options"]="nosniff";ctx.Response.Headers["Referrer-Policy"]="same-origin";ctx.Response.Headers["Content-Security-Policy"]="default-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'self'";try{await next();}catch(RuleException ex){if(ctx.Request.Path.StartsWithSegments("/api")){ctx.Response.StatusCode=400;await ctx.Response.WriteAsJsonAsync(new{error=ex.Message});}else throw;}});
app.UseStaticFiles();app.UseRouting();app.UseRateLimiter();app.UseAuthentication();app.UseAuthorization();app.UseAntiforgery();
app.MapRazorPages();app.MapGroup("/api/auth").MapIdentityApi<AppUser>().RequireRateLimiting("auth");
app.MapGet("/api/categories",async(AppDbContext db)=>await db.Categories.AsNoTracking().Where(c=>c.Active).OrderBy(c=>c.SortOrder).ToListAsync());
app.MapGet("/api/professionals",async(string? q,int? category,string? city,bool? available,Marketplace m)=>(await m.Search(q,category,city,available??false)).Select(PublicProfile));
app.MapGet("/api/professionals/{id:int}",async(int id,Marketplace m)=>PublicProfile(await m.Profile(id)));
var api=app.MapGroup("/api").RequireAuthorization(p=>p.AddAuthenticationSchemes(IdentityConstants.BearerScheme).RequireAuthenticatedUser());
api.MapGet("/me",async(ClaimsPrincipal u,UserManager<AppUser> users,AppDbContext db)=>{var id=u.FindFirstValue(ClaimTypes.NameIdentifier)!;var account=await users.FindByIdAsync(id);return Results.Ok(new{id,email=account!.Email,name=account.DisplayName,professional=await db.Professionals.AsNoTracking().Where(p=>p.UserId==id).Select(p=>new{p.Id,p.Name,p.Approved}).FirstOrDefaultAsync()});});
api.MapGet("/appointments",async(ClaimsPrincipal u,Marketplace m)=>(await m.Appointments(Uid(u))).Select(a=>new{a.Id,a.ProfessionalId,professional=a.Professional.Name,a.CustomerId,customer=a.Customer.DisplayName,a.StartUtc,a.EndUtc,status=a.Status.ToString(),a.Description,a.Address,a.ProposedStartUtc,a.ProposedById,isProfessional=a.Professional.UserId==Uid(u)}));
api.MapPost("/appointments",async(BookingInput input,ClaimsPrincipal u,Marketplace m)=>{var a=await m.Book(Uid(u),input.ProfessionalId,input.StartUtc,input.Description,input.Address);return Results.Ok(new{a.Id,status=a.Status.ToString()});});
api.MapPost("/appointments/{id:int}/action",async(int id,ActionInput input,ClaimsPrincipal u,Marketplace m)=>{await m.Transition(Uid(u),id,input.Action,input.ProposedStartUtc);return Results.Ok();});
api.MapGet("/messages/{pro:int}",async(int pro,string? customer,ClaimsPrincipal u,Marketplace m)=>await m.Conversation(Uid(u),pro,customer));
api.MapPost("/messages/{pro:int}",async(int pro,MessageInput input,ClaimsPrincipal u,Marketplace m)=>{await m.Send(Uid(u),pro,input.CustomerId,input.Text);return Results.Ok();});
api.MapGet("/inbox",async(ClaimsPrincipal u,AppDbContext db)=>{var id=Uid(u);var owned=await db.Professionals.Where(p=>p.UserId==id).Select(p=>p.Id).ToListAsync();var messages=await db.Messages.AsNoTracking().Where(m=>m.CustomerId==id||owned.Contains(m.ProfessionalId)).OrderByDescending(m=>m.CreatedUtc).ToListAsync();return messages.GroupBy(m=>new{m.ProfessionalId,m.CustomerId}).Select(g=>new{g.Key.ProfessionalId,g.Key.CustomerId,text=g.First().Text,time=g.First().CreatedUtc});});
api.MapPost("/reviews",async(ReviewInput input,ClaimsPrincipal u,Marketplace m)=>{await m.Review(Uid(u),input.AppointmentId,input.Rating,input.Text);return Results.Ok();});
api.MapGet("/professional",async(ClaimsPrincipal u,AppDbContext db)=>{var id=Uid(u);return await db.Professionals.AsNoTracking().Where(p=>p.UserId==id).Select(p=>new{p.Id,p.Name,p.CategoryId,p.City,p.Neighborhood,p.Bio,p.Phone,p.HourlyRate,p.YearsExperience,p.StartHour,p.EndHour,p.AcceptingRequests,p.Approved}).SingleOrDefaultAsync();});
api.MapPost("/professional",async(ProfessionalInput input,ClaimsPrincipal u,AppDbContext db)=>{var id=Uid(u);var error=ProfessionalInput.Validate(input);if(error!=null)return Results.BadRequest(new{error});if(!await db.Categories.AnyAsync(c=>c.Id==input.CategoryId))return Results.BadRequest(new{error="Choose a category."});var p=await db.Professionals.SingleOrDefaultAsync(x=>x.UserId==id);if(p==null){p=new(){UserId=id};db.Add(p);}input.Apply(p);await db.SaveChangesAsync();return Results.Ok(new{p.Id,p.Approved});});
api.MapGet("/notifications",async(ClaimsPrincipal u,AppDbContext db)=>{var id=Uid(u);return await db.Notifications.AsNoTracking().Where(n=>n.UserId==id).OrderByDescending(n=>n.CreatedUtc).Take(100).ToListAsync();});
api.MapPost("/notifications/read",async(ClaimsPrincipal u,AppDbContext db)=>{var id=Uid(u);await db.Notifications.Where(n=>n.UserId==id&&!n.Read).ExecuteUpdateAsync(s=>s.SetProperty(n=>n.Read,true));return Results.Ok();});
api.MapGet("/favorites",async(ClaimsPrincipal u,AppDbContext db,Marketplace m)=>{var id=Uid(u);var ids=await db.Favorites.Where(f=>f.UserId==id).Select(f=>f.ProfessionalId).ToListAsync();return (await m.Search()).Where(p=>ids.Contains(p.Id)).Select(PublicProfile);});
api.MapPost("/favorites/{pro:int}",async(int pro,ClaimsPrincipal u,AppDbContext db,Marketplace m)=>{await m.Profile(pro);var id=Uid(u);var f=await db.Favorites.SingleOrDefaultAsync(f=>f.UserId==id&&f.ProfessionalId==pro);if(f==null)db.Favorites.Add(new(){UserId=id,ProfessionalId=pro});else db.Favorites.Remove(f);await db.SaveChangesAsync();return Results.Ok();});
api.MapPost("/report/{pro:int}",async(int pro,ReportInput input,ClaimsPrincipal u,AppDbContext db,Marketplace m)=>{await m.Profile(pro);if(string.IsNullOrWhiteSpace(input.Reason)||input.Reason.Length>2000)return Results.BadRequest(new{error="Enter a reason up to 2000 characters."});db.Reports.Add(new(){UserId=Uid(u),ProfessionalId=pro,Reason=input.Reason.Trim()});await db.SaveChangesAsync();return Results.Ok();});
api.MapGet("/blocks",async(ClaimsPrincipal u,AppDbContext db)=>{var id=Uid(u);return await (from b in db.Blocks join p in db.Professionals on b.BlockedUserId equals p.UserId where b.UserId==id select new{p.Id,p.Name}).ToListAsync();});
api.MapPost("/block/{pro:int}",async(int pro,BlockInput input,ClaimsPrincipal u,AppDbContext db)=>{var p=await db.Professionals.FindAsync(pro);if(p==null)return Results.NotFound();var id=Uid(u);if(p.UserId==id)return Results.BadRequest(new{error="Cannot block yourself."});var block=await db.Blocks.SingleOrDefaultAsync(b=>b.UserId==id&&b.BlockedUserId==p.UserId);if(input.Blocked&&block==null)db.Blocks.Add(new(){UserId=id,BlockedUserId=p.UserId});else if(!input.Blocked&&block!=null)db.Blocks.Remove(block);await db.SaveChangesAsync();return Results.Ok();});
api.MapGet("/service-requests",async(ClaimsPrincipal u,RequestService service)=>(await service.List(u)).Select(r=>RequestService.Dto(r,Uid(u))));
api.MapGet("/service-requests/{id:int}",async(int id,ClaimsPrincipal u,RequestService service)=>RequestService.Dto(await service.Get(u,id),Uid(u)));
api.MapPost("/service-requests",async(ServiceRequestInput input,ClaimsPrincipal u,RequestService service)=>{var r=await service.Create(u,input);return Results.Ok(new{r.Id,status=r.Status.ToString()});});
api.MapPost("/service-requests/{id:int}/edit",async(int id,ServiceRequestInput input,ClaimsPrincipal u,RequestService service)=>{await service.Edit(u,id,input);return Results.Ok();});
api.MapPost("/service-requests/{id:int}/action",async(int id,RequestActionInput input,ClaimsPrincipal u,RequestService service)=>{await service.Change(u,id,input.Action,input.ProfessionalId);return Results.Ok();});
api.MapGet("/service-requests/{id:int}/photo",async(int id,ClaimsPrincipal u,RequestService service,HttpContext context)=>{var p=await service.Photo(u,id);context.Response.Headers.CacheControl="private, no-store";return Results.File(p.Bytes,p.Type);});
app.MapGet("/health",()=>Results.Ok(new{status="ok"}));
await using(var scope=app.Services.CreateAsyncScope()){await Seed.Run(scope.ServiceProvider,app.Environment.IsDevelopment()&&builder.Configuration.GetValue<bool>("SeedDemo"),builder.Configuration["DemoPassword"]);}
await app.RunAsync();
static string Uid(ClaimsPrincipal u)=>u.FindFirstValue(ClaimTypes.NameIdentifier)!;
static object PublicProfile(Professional p)=>new{p.Id,p.Name,p.City,p.Neighborhood,p.Bio,p.Phone,p.HourlyRate,p.YearsExperience,p.AcceptingRequests,p.StartHour,p.EndHour,category=p.Category.Name,p.CategoryId,icon=p.Category.Icon,rating=p.Reviews.Count>0?(double?)p.Reviews.Average(r=>r.Rating):null,reviewCount=p.Reviews.Count,reviews=p.Reviews.Select(r=>new{r.Rating,r.Text})};
public record BookingInput(int ProfessionalId,DateTime StartUtc,string Description,string Address);
public record ActionInput(string Action,DateTime? ProposedStartUtc);
public record MessageInput(string Text,string? CustomerId);
public record ReviewInput(int AppointmentId,int Rating,string Text);
public record ProfessionalInput(string Name,int CategoryId,string City,string Neighborhood,string Bio,string Phone,decimal HourlyRate,int YearsExperience,int StartHour,int EndHour,bool AcceptingRequests){
 public static string? Validate(ProfessionalInput p)=>string.IsNullOrWhiteSpace(p.Name)||p.Name.Length>100||string.IsNullOrWhiteSpace(p.City)||p.City.Length>100||p.Neighborhood==null||p.Neighborhood.Length>100||p.Bio==null||p.Bio.Length>2000||p.Phone==null||p.Phone.Length>30||p.HourlyRate<0||p.HourlyRate>10000||p.YearsExperience<0||p.YearsExperience>70||p.StartHour<0||p.EndHour>24||p.StartHour>=p.EndHour?"Check your profile fields and working hours.":null;
 public void Apply(Professional p){p.Name=Name.Trim();p.CategoryId=CategoryId;p.City=City.Trim();p.Neighborhood=Neighborhood.Trim();p.Bio=Bio.Trim();p.Phone=Phone.Trim();p.HourlyRate=HourlyRate;p.YearsExperience=YearsExperience;p.StartHour=StartHour;p.EndHour=EndHour;p.AcceptingRequests=AcceptingRequests;p.Approved=false;}
}

public record ReportInput(string Reason);

public record BlockInput(bool Blocked=true);

public record RequestActionInput(string Action,int? ProfessionalId=null);
