#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/restore.sh backups/backup-file-name.dump"
  exit 1
fi

repository_root_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
database_environment_file="${repository_root_directory}/docker/db/.env"
local_backup_file_path="$1"

if [[ ! -f "${database_environment_file}" ]]; then
  echo "Missing ${database_environment_file}. Create it from docker/db/.env.example."
  exit 1
fi

if [[ ! -f "${local_backup_file_path}" ]]; then
  echo "Backup file not found: ${local_backup_file_path}"
  exit 1
fi

set -a
source "${database_environment_file}"
set +a

container_restore_file_path="/tmp/restore_$(date +%Y%m%d_%H%M%S).dump"

echo "Copying backup file into PostgreSQL container"
docker cp "${local_backup_file_path}" "hotel-booking-postgres:${container_restore_file_path}"

echo "Terminating active database connections for ${POSTGRES_DB}"
docker exec hotel-booking-postgres psql \
  -U "${POSTGRES_USER}" \
  -d postgres \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${POSTGRES_DB}' AND pid <> pg_backend_pid();"

echo "Dropping database ${POSTGRES_DB}"
docker exec hotel-booking-postgres psql \
  -U "${POSTGRES_USER}" \
  -d postgres \
  -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};"

echo "Creating database ${POSTGRES_DB}"
docker exec hotel-booking-postgres psql \
  -U "${POSTGRES_USER}" \
  -d postgres \
  -c "CREATE DATABASE ${POSTGRES_DB};"

echo "Restoring database ${POSTGRES_DB}"
docker exec hotel-booking-postgres pg_restore \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  --clean \
  --if-exists \
  "${container_restore_file_path}"

docker exec hotel-booking-postgres rm -f "${container_restore_file_path}"

echo "Restore completed successfully"