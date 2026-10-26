#!/usr/bin/env bash
# Recoverable SaaS Decommission — MySQL restore verifier (Bash)
# Usage: bash mysql/verify-restore.sh <backup.sql|backup.sql.gz> [assertions.sql]
# Requirements: Bash 4+, Docker Engine, OpenSSL, gzip (only for .sql.gz)
# Assertions must return exactly one scalar value of 1 when all checks pass.
# No connection to a source/production database is made.

set -Eeuo pipefail

readonly IMAGE="mysql:8.0"
readonly DATABASE="restore_verification"
CONTAINER=""
SECRET_DIR=""
CONTAINER_CREATED=0
TABLE_COUNT=""
ASSERTION_STATUS="NOT RUN"

info() { printf '[INFO] %s\n' "$*"; }
pass() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fail() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

cleanup() {
    local status=$?
    trap - EXIT INT TERM
    if (( CONTAINER_CREATED )); then
        if docker rm -f -v "$CONTAINER" >/dev/null 2>&1; then
            info "Removed disposable MySQL container."
        else
            warn "Container cleanup failed: $CONTAINER (remove manually)."
            status=1
        fi
    fi
    if [[ -n "$SECRET_DIR" && -d "$SECRET_DIR" ]]; then
        rm -f -- "$SECRET_DIR/mysql_password" || status=1
        rmdir -- "$SECRET_DIR" || status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Only file-based inputs. No production connection strings or credentials.
if (( $# < 1 || $# > 2 )); then
    printf 'Usage: %s <backup.sql|backup.sql.gz> [assertions.sql]\n' "$0" >&2
    exit 2
fi
DUMP="$1"
ASSERTIONS="${2:-}"
[[ -f "$DUMP" && -r "$DUMP" && -s "$DUMP" ]] || fail 'Backup must be a readable, nonempty file.'
case "$DUMP" in
    *.sql|*.sql.gz) ;;
    *) fail 'Unsupported format. Supply .sql or .sql.gz.' ;;
esac
if [[ -n "$ASSERTIONS" ]]; then
    [[ -f "$ASSERTIONS" && -r "$ASSERTIONS" && -s "$ASSERTIONS" ]] || fail 'Verification SQL must be a readable, nonempty file.'
fi
for executable in docker openssl; do
    command -v "$executable" >/dev/null 2>&1 || fail "Missing executable: $executable"
done
if [[ "$DUMP" == *.sql.gz ]]; then
    command -v gzip >/dev/null 2>&1 || fail 'Missing executable: gzip'
    gzip -t -- "$DUMP" || fail 'Compressed backup failed gzip integrity check.'
fi
docker info >/dev/null 2>&1 || fail 'Docker engine is not available.'
info 'Input and Docker preflight checks passed.'

# Password stays in a temporary file accessible to the container as a read-only secret.
# The password is not entered into shell history or a Docker command-line argument.
SECRET_DIR="$(mktemp -d)" || fail 'Could not make temporary secrets directory.'
chmod 700 "$SECRET_DIR"
openssl rand -hex 24 > "$SECRET_DIR/mysql_password" || fail 'Could not generate a temporary password.'
chmod 600 "$SECRET_DIR/mysql_password"
CONTAINER="rsd-restore-$(openssl rand -hex 8)"

info "Checking Docker image: $IMAGE"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker pull "$IMAGE" || fail 'MySQL image download failed.'
fi

info 'Starting isolated MySQL container (no published ports, no network).'
# Docker must not silently create the secret source path as an empty directory.
# No named volumes or existing containers are modified.
if docker run -d \
    --name "$CONTAINER" \
    --network none \
    --mount "type=bind,src=$SECRET_DIR/mysql_password,dst=/run/secrets/mysql_password,readonly" \
    -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_password \
    -e MYSQL_DATABASE="$DATABASE" \
    "$IMAGE" >/dev/null; then
    CONTAINER_CREATED=1
else
    # A failed docker run can still leave behind a created container; remove only our unique name.
    docker rm -f -v "$CONTAINER" >/dev/null 2>&1 || true
    fail 'Docker could not start the MySQL test container.'
fi

# Runs mysql within container, reading secret there; nothing sensitive is passed in argv.
mysql_query() {
    docker exec -i "$CONTAINER" sh -c \
        'MYSQL_PWD="$(cat /run/secrets/mysql_password)"; export MYSQL_PWD; exec mysql -uroot -N -B restore_verification'
}

info 'Waiting for authenticated MySQL readiness (up to 120 seconds).'
READY=0
for (( attempt=1; attempt<=60; attempt++ )); do
    # MySQL's internal bootstrap server may respond before the final server is ready.
    # SELECT 1 against our created database proves successful authentication and init.
    if response="$(printf 'SELECT 1;\n' | mysql_query 2>/dev/null)" && [[ "$response" == '1' ]]; then
        READY=1
        break
    fi
    running="$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)"
    [[ "$running" == 'true' ]] || fail 'MySQL container exited before readiness.'
    sleep 2
done
(( READY == 1 )) || fail 'MySQL did not authenticate and become ready within 120 seconds.'
pass 'MySQL authenticated and ready.'

info 'Importing SQL backup into disposable database.'
if [[ "$DUMP" == *.sql.gz ]]; then
    gzip -dc -- "$DUMP" | mysql_query || fail 'Import failed (decompression or MySQL error).'
else
    mysql_query < "$DUMP" || fail 'Import failed (MySQL error).'
fi
pass 'SQL import completed.'

TABLE_COUNT="$(printf 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_type="BASE TABLE";\n' | mysql_query)" \
    || fail 'Could not query restored database schema.'
[[ "$TABLE_COUNT" =~ ^[0-9]+$ ]] || fail 'Invalid table-count response.'
(( TABLE_COUNT > 0 )) || fail 'No base tables were restored.'
pass "Restored base tables: $TABLE_COUNT"

if [[ -n "$ASSERTIONS" ]]; then
    info 'Running supplied application-specific SQL assertions.'
    # IMPORTANT: MySQL itself does not restrict SQL files to read-only operations.
    # Supply only trusted verification SQL; this tool executes it as root in the container.
    result="$(mysql_query < "$ASSERTIONS")" || fail 'Verification SQL could not execute.'
    [[ "$result" == '1' ]] || fail 'Assertions failed (expected precisely one scalar result: 1).'
    ASSERTION_STATUS='PASS'
    pass 'Custom verification assertions passed.'
else
    warn 'No assertions supplied: source-to-restore record completeness NOT verified.'
fi

printf '\nRESTORE VERIFICATION: PASS\nMySQL image: %s\nRestored base tables: %s\nCustom assertions: %s\n' \
    "$IMAGE" "$TABLE_COUNT" "$ASSERTION_STATUS"
# Cleanup runs via EXIT trap. If cleanup fails, overall exit status becomes nonzero.
