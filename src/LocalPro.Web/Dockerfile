FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /source
COPY src/LocalPro.Web/LocalPro.Web.csproj src/LocalPro.Web/
RUN dotnet restore src/LocalPro.Web/LocalPro.Web.csproj
COPY src/LocalPro.Web/ src/LocalPro.Web/
RUN dotnet publish src/LocalPro.Web/LocalPro.Web.csproj -c Release -o /app --no-restore
FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "LocalPro.Web.dll"]
