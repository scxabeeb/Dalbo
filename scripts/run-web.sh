#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${ConnectionStrings__Default:?Set ConnectionStrings__Default to your MySQL connection string}"
export ASPNETCORE_ENVIRONMENT="${ASPNETCORE_ENVIRONMENT:-Development}"
export ASPNETCORE_URLS="${ASPNETCORE_URLS:-http://localhost:5080}"
dotnet run --project src/LocalPro.Web --no-launch-profile
