using System.ComponentModel.DataAnnotations;
namespace LocalPro.Web.Domain;
public class SiteSettings {
 public int Id { get; set; } = 1;
 [Required, MaxLength(80)] public string AppName { get; set; } = "DANXALIYE";
 [MaxLength(160)] public string Tagline { get; set; } = "Baahidaada, Xalkeeda.";
 [Required, RegularExpression("^#[0-9a-fA-F]{6}$")] public string PrimaryColor { get; set; } = "#0e305d";
 [Required, RegularExpression("^#[0-9a-fA-F]{6}$")] public string AccentColor { get; set; } = "#ff6b0b";
 [Required, MaxLength(80)] public string City { get; set; } = "Garowe";
 [MaxLength(160)] public string HeroTitle { get; set; } = "Maxaad u baahan tahay maanta?";
 [MaxLength(300)] public string HeroDescription { get; set; } = "Farsamoyaqaan albaabkaaga kuugu yimaada.";
 [EmailAddress, MaxLength(200)] public string? ContactEmail { get; set; }
 [MaxLength(30)] public string? ContactPhone { get; set; }
 [Required, RegularExpression("^[A-Z]{3}$")] public string Currency { get; set; } = "USD";
 public bool RegistrationEnabled { get; set; } = true;
 public bool ProductsEnabled { get; set; } = true;
 public byte[]? Logo { get; set; }
 [MaxLength(30)] public string? LogoContentType { get; set; }
 public DateTime UpdatedUtc { get; set; } = DateTime.UtcNow;
}
public class Product {
 public int Id { get; set; }
 [Required, MaxLength(120)] public string Name { get; set; } = "";
 [MaxLength(2000)] public string Description { get; set; } = "";
 [MaxLength(80)] public string Category { get; set; } = "";
 [Range(0, 10000000)] public decimal Price { get; set; }
 [Range(0, 1000000)] public int Stock { get; set; }
 public bool Active { get; set; } = true;
 public int SortOrder { get; set; }
 public byte[]? Image { get; set; }
 [MaxLength(30)] public string? ImageContentType { get; set; }
 public DateTime UpdatedUtc { get; set; } = DateTime.UtcNow;
}
