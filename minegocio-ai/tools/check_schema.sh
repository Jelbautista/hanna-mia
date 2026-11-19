#!/usr/bin/env bash
# Valida el esquema borrador de Fase 0 contra un PostgreSQL real.
#   tools/check_schema.sh
# Por defecto usa el clúster local (como root ejecuta psql como usuario 'postgres').
# Con PGHOST/PGUSER definidos usa ese servidor (el rol debe poder crear bases y roles).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB="minegocio_phase0_check_$$"

psql_run() {  # psql_run <db> [args...]  (SQL por stdin o -c)
  local db="$1"; shift
  if [[ -z "${PGHOST:-}" && "$(id -u)" == "0" ]]; then
    su postgres -c "psql -X -q -v ON_ERROR_STOP=1 -d $db $(printf '%q ' "$@")"
  else
    psql -X -q -v ON_ERROR_STOP=1 -d "$db" "$@"
  fi
}

cleanup() {
  psql_run postgres -c "DROP DATABASE IF EXISTS $DB" >/dev/null 2>&1 || true
  psql_run postgres -c "DROP ROLE IF EXISTS minegocio_app_test" >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup

psql_run postgres -c "CREATE DATABASE $DB"

echo "== Cargando esquema (db/phase0/schema_draft.sql) =="
psql_run "$DB" < "$ROOT/db/phase0/schema_draft.sql"
echo "Tablas: $(psql_run "$DB" -At -c "SELECT count(*) FROM pg_tables WHERE schemaname='public'")"

echo "== Ejecutando aserciones (db/phase0/schema_checks.sql) =="
psql_run "$DB" < "$ROOT/db/phase0/schema_checks.sql" 2>&1 \
  | sed -E 's/^psql:[^:]*:[0-9]+: //; s/^NOTICE:  //'

echo "== OK: esquema cargado y todas las aserciones pasaron =="
