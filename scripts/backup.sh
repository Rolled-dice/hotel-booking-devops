#!/usr/bin/env bash
set -euo pipefail

repository_root_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
database_environment_file="${repository_root_directory}/docker/db/.env"
backup_directory="${repository_root_directory}/backups"

if [[ ! -f "${database_environment_file}" ]]; then
  echo "Missing ${database_environment_file}. Create it from docker/db/.env.example."
  exit 1
fi

set -a
source "${database_environment_file}"
set +a

mkdir -p "${backup_directory}"

backup_timestamp="$(date +%Y%m%d_%H%M%S)"
backup_file_name="${POSTGRES_DB}_${backup_timestamp}.dump"
container_backup_path="/tmp/${backup_file_name}"
local_backup_path="${backup_directory}/${backup_file_name}"

echo "Creating PostgreSQL backup at ${local_backup_path}"

docker exec hotel-booking-postgres pg_dump \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  -F c \
  -f "${container_backup_path}"

docker cp "hotel-booking-postgres:${container_backup_path}" "${local_backup_path}"

docker exec hotel-booking-postgres rm -f "${container_backup_path}"

echo "Backup completed successfully"
echo "${local_backup_path}"