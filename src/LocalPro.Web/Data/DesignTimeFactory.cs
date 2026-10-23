using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
namespace LocalPro.Web.Data;
public class DesignTimeFactory : IDesignTimeDbContextFactory<AppDbContext> {
 public AppDbContext CreateDbContext(string[] args) => new(new DbContextOptionsBuilder<AppDbContext>().UseMySql(Environment.GetEnvironmentVariable("ConnectionStrings__Default") ?? "Server=127.0.0.1;Database=localpro;User=localpro;Password=CHANGE_ME",new MySqlServerVersion(new Version(8,4,0))).Options);
}
