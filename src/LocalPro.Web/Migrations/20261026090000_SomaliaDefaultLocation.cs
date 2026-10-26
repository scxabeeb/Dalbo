using LocalPro.Web.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
namespace LocalPro.Web.Migrations;
[DbContext(typeof(AppDbContext))]
[Migration("20261026090000_SomaliaDefaultLocation")]
public class SomaliaDefaultLocation : Migration {
 protected override void Up(MigrationBuilder migrationBuilder) {
  migrationBuilder.Sql("UPDATE SiteSettings SET City = 'Somalia', UpdatedUtc = UTC_TIMESTAMP(6) WHERE Id = 1");
 }
 protected override void Down(MigrationBuilder migrationBuilder) {
  migrationBuilder.Sql("UPDATE SiteSettings SET City = 'Garowe', UpdatedUtc = UTC_TIMESTAMP(6) WHERE Id = 1");
 }
}
