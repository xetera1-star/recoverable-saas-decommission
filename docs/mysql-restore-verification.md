# MySQL restore verification

This guide covers the repository's Docker-based MySQL restore verifier, `mysql/verify-restore.sh`.

The verifier restores a supplied SQL dump to a **disposable MySQL 8.0 container**, confirms that the restored database has base tables, and optionally runs application-specific SQL assertions. It then removes the temporary container. It does not connect to a production database.

## Prerequisites

- Docker Engine or Docker Desktop with the Docker daemon running.
- Bash and a working Docker CLI.
- Access to the `mysql:8.0` container image (Docker may need to download it on first use).
- A readable, nonempty SQL dump compatible with MySQL 8.0.

**Windows:** use Docker Desktop with WSL integration enabled for your Ubuntu distribution. Run the Bash verifier through Ubuntu WSL, not through PowerShell directly. A separate PowerShell wrapper is not included.

## Quick start

From the repository root on Linux or inside Ubuntu WSL:

```bash
bash mysql/verify-restore.sh fixtures/sample-schema.sql mysql/verification-queries.sql
```

From **Windows PowerShell**, with Docker Desktop running and Ubuntu WSL integrated:

```powershell
wsl -d Ubuntu -- bash mysql/verify-restore.sh fixtures/sample-schema.sql mysql/verification-queries.sql
```

The Windows command assumes that PowerShell's current directory is the cloned repository and that the WSL distribution is named `Ubuntu`. If yours has a different name, obtain it with `wsl --list --quiet` and substitute the correct name.

If Docker or MySQL becomes unresponsive, stop the command and diagnose the Docker environment. For a bounded troubleshooting run in Windows PowerShell:

```powershell
wsl -d Ubuntu -- timeout -k 10s 180s bash mysql/verify-restore.sh fixtures/sample-schema.sql mysql/verification-queries.sql
```

The 180-second timeout is a **troubleshooting safeguard**, not a guarantee that larger restores will finish in that time.

## Verifying your own backup

Pass the SQL dump path as the first argument. Pass an optional SQL assertions file as the second:

```bash
bash mysql/verify-restore.sh /path/to/backup.sql /path/to/checks.sql
```

For a dump without custom assertions:

```bash
bash mysql/verify-restore.sh /path/to/backup.sql
```

Use paths visible to the environment executing Bash. From Ubuntu WSL, Windows drives typically appear under `/mnt/c/`, `/mnt/d/`, and so on. Keep backups **outside the Git repository**. Never commit production SQL dumps, secret configuration, or decrypted archive material.

The included `mysql/verification-queries.sql` is specific to the **fictional fixture**. It expects the fixture's tables and row counts. Write your own SQL assertions for a real application; do not reuse fixture expectations against production-derived backups.

A successful fixture run includes:

```text
[PASS] SQL import completed.
[PASS] Restored base tables: 3
[PASS] Custom verification assertions passed.

RESTORE VERIFICATION: PASS
MySQL image: mysql:8.0
Restored base tables: 3
Custom assertions: PASS
[INFO] Removed disposable MySQL container.
```

A failure must be treated as a **failed verification**, not an acceptable backup. The verifier has also been exercised with a missing input file and an intentionally failing assertion. A missing file is rejected before container creation; a failed assertion produces a failure result and container cleanup.

## What a PASS means

For the database dump under test, a PASS indicates that the verifier could:

1. Start a disposable MySQL 8.0 instance.
2. Import the supplied SQL successfully.
3. Detect restored base tables.
4. Run the supplied custom assertions successfully, if provided.
5. Remove the disposable container at the end.

This is a useful **database-level recovery check**, but it is **not** proof of a complete application recovery, a tested recovery time objective, or business continuity readiness. A full recovery exercise also requires application files, persistent uploads, encryption keys, configuration, background workers, dependencies, DNS/TLS arrangements and operational smoke tests appropriate to the system.

## Isolation and security

The verifier is designed to launch MySQL without published ports and with Docker networking disabled. This reduces the test container's network exposure but does not make untrusted dumps safe: SQL imports are still executable workloads inside a privileged database process. Only restore data from sources you are authorized to handle and trust.

- Never publish real backups, database credentials, `.env` files, encryption keys or customer information in GitHub issues or commits.
- Treat decrypted SQL and temporary output as sensitive; limit access and remove it when no longer required.
- Verify archive encryption, checksums, retention policies and access controls **separately**.
- Avoid running the verifier on a shared host holding sensitive workloads unless its Docker security posture is understood.
- The test uses MySQL **8.0**. Validate compatibility separately if production uses another server version or database product.

## Current validation status

The Bash verifier has been exercised successfully on **Windows PowerShell → Ubuntu WSL → Docker Desktop** using the fictional SQL fixture:

- Successful import, table check and custom assertions.
- Rejection of a missing backup file.
- Rejection of an intentionally false SQL assertion, with container cleanup.

A compressed-dump test, deliberate SQL corruption test and native Linux host test have **not yet been documented as passing**. Do not infer those outcomes from the existing tests.
