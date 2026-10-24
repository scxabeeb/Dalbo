using LocalPro.Web.Data;
using LocalPro.Web.Domain;
using Microsoft.EntityFrameworkCore;
namespace LocalPro.Web.Services;
public class ConfigurationService(AppDbContext db) {
 public async Task<SiteSettings> Get() => await db.SiteSettings.AsNoTracking().SingleOrDefaultAsync(s => s.Id == 1) ?? new();
 public static object Public(SiteSettings s) => new { s.AppName, s.Tagline, s.PrimaryColor, s.AccentColor, s.City, s.HeroTitle, s.HeroDescription, s.ContactEmail, s.ContactPhone, s.Currency, s.RegistrationEnabled, s.ProductsEnabled, logoUrl = s.Logo == null ? "/brand/danxaliye-logo.png" : $"/api/settings/logo?v={s.UpdatedUtc.Ticks}" };
 public static async Task<(byte[] Bytes, string Type)> ReadImage(IFormFile file) {
  if(file.Length == 0 || file.Length > 2 * 1024 * 1024) throw new RuleException("Choose a PNG or JPEG image up to 2 MB.");
  using var stream = new MemoryStream(); await file.CopyToAsync(stream); var bytes = stream.ToArray();
  var png = bytes.Length >= 24 && bytes.AsSpan(0,8).SequenceEqual(new byte[]{137,80,78,71,13,10,26,10});
  var jpeg = bytes.Length >= 4 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255 && bytes[^2] == 255 && bytes[^1] == 217;
  if(!png && !jpeg) throw new RuleException("Only PNG and JPEG images are supported.");
  return (bytes, png ? "image/png" : "image/jpeg");
 }
}
