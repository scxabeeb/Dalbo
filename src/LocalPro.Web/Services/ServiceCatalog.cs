using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Services;
public static class ServiceCatalog {
 public static readonly (string Name,string Icon,string Group,string Description)[] Items=[
 ("Gaadiid Dalbo","▰","Gaadiid","Gaadiid kuu qaada meesha aad u socoto."),
 ("Bajaaj Dalbo","♧","Gaadiid","Bajaaj magaalada gudaheeda."),
 ("Koronto-yaqaan","ϟ","Farsamo","Wiring, nalal, sockets iyo ciladaha korontada."),
 ("Tuubiiste","♧","Guriga","Tuubooyinka, biyaha iyo dayactirka musqusha."),
 ("Alxanle","♨","Farsamo","Alxanka iyo dayactirka biraha."),
 ("Rinjiile","▥","Guriga","Rinjiyeynta guryaha iyo goobaha shaqada."),
 ("AC & Qaboojiye","❄","Farsamo","Rakibidda iyo dayactirka qaboojiyeyaasha."),
 ("Nijaar","⌁","Guriga","Alaabta guriga iyo shaqada alwaaxda."),
 ("Solar","☀","Farsamo","Rakibidda iyo dayactirka tamarta qorraxda."),
 ("Nadaafad","✦","Guriga","Nadaafadda guriga iyo xafiiska."),
 ("Mechanic","⚒","Farsamo","Dayactirka iyo hagaajinta baabuurta."),
 ("CCTV & Amni","◉","Farsamo","Kaamirooyinka iyo qalabka amniga."),
 ("Electronics","▣","Farsamo","Dayactirka qalabka elektaroonigga ah."),
 ("Rarid & Guuritaan","▰","Gaadiid","Raridda alaabta iyo guuritaanka."),
 ("Delivery","▧","Gaadiid","Gaarsiinta alaabta iyo xirmooyinka."),
 ("Dhirayn & Beer","♧","Guriga","Dhiraynta iyo daryeelka beeraha.")];
 public static async Task Sync(AppDbContext db){
 var cats=await db.Categories.ToListAsync();
 var legacy=new Dictionary<string,string>{{"Electrical","Koronto-yaqaan"},{"Plumbing","Tuubiiste"},{"Air conditioning","AC & Qaboojiye"}};
 foreach(var c in cats){if(legacy.TryGetValue(c.Name,out var name))c.Name=name;if(c.Name=="Refrigeration")c.Active=false;}
 for(var i=0;i<Items.Length;i++){var x=Items[i];var c=cats.FirstOrDefault(c=>c.Name==x.Name);if(c==null){c=new(){Name=x.Name};db.Categories.Add(c);}c.Icon=x.Icon;c.Group=x.Group;c.Description=x.Description;c.Active=true;c.SortOrder=i;}
 await db.SaveChangesAsync();
 }
 public static string IconKey(string name)=>name switch{"Gaadiid Dalbo"=>"car","Bajaaj Dalbo"=>"tuktuk","Koronto-yaqaan"=>"bolt","Tuubiiste"=>"drop","Alxanle"=>"fire","Rinjiile"=>"paint","AC & Qaboojiye"=>"snow","Nijaar"=>"hammer","Solar"=>"sun","Nadaafad"=>"spark","Mechanic"=>"wrench","CCTV & Amni"=>"cctv","Electronics"=>"monitor","Rarid & Guuritaan"=>"truck","Delivery"=>"box","Dhirayn & Beer"=>"leaf",_=>"grid"};
 public static string Status(ServiceRequestStatus s)=>s switch{ServiceRequestStatus.Received=>"Dalabka waa la helay",ServiceRequestStatus.Assigned=>"Farsamoyaqaan ayaa loo xilsaaray",ServiceRequestStatus.OnTheWay=>"Jidka ayuu ku jiraa",ServiceRequestStatus.InProgress=>"Shaqada waa socotaa",ServiceRequestStatus.Completed=>"Shaqada waa la dhammeeyay",_=>"Dalabka waa la joojiyay"};
 public static string When(string s)=>s switch{"Now"=>"Hadda","Today"=>"Maanta",_=>"Berri"};
}
