using LocalPro.Web.Domain;using LocalPro.Web.Services;using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LocalPro.Web.Pages.Requests;[Authorize]public class IndexModel(RequestService service):PageModel{public List<ServiceRequest> Items{get;set;}=[];public async Task OnGetAsync()=>Items=await service.List(User);}
