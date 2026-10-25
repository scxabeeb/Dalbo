using LocalPro.Web.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
namespace LocalPro.Web.Migrations;
[DbContext(typeof(AppDbContext))]
[Migration("20261025170000_CtcDalboBrand")]
public class CtcDalboBrand : Migration {
 protected override void Up(MigrationBuilder migrationBuilder) {
  // Apply the owner's new supplied identity without changing business preferences or accounts.
  migrationBuilder.Sql("UPDATE SiteSettings SET AppName = 'CTC DALBO', Tagline = 'Adeegga aad rabto, halka aad joogto.', Logo = NULL, LogoContentType = NULL, UpdatedUtc = UTC_TIMESTAMP(6) WHERE Id = 1");
 }
 protected override void Down(MigrationBuilder migrationBuilder) {
  migrationBuilder.Sql("UPDATE SiteSettings SET AppName = 'DANXALIYE', Tagline = 'Baahidaada, Xalkeeda.', UpdatedUtc = UTC_TIMESTAMP(6) WHERE Id = 1");
 }
}
