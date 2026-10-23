#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${ConnectionStrings__Default:-}" && ! -f src/LocalPro.Web/appsettings.Local.json ]]; then
  echo "Set ConnectionStrings__Default or create src/LocalPro.Web/appsettings.Local.json" >&2
  exit 1
fi
export ASPNETCORE_ENVIRONMENT="${ASPNETCORE_ENVIRONMENT:-Development}"
export ASPNETCORE_URLS="${ASPNETCORE_URLS:-http://localhost:5080}"
dotnet run --project src/LocalPro.Web --no-launch-profile
