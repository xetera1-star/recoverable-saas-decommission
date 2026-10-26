# Recoverable SaaS Decommission

**Practical tools and operational guidance for decommissioning SaaS applications without losing the ability to restore them.**

Decommissioning an application involves more than shutting down servers, deleting databases and cancelling hosting subscriptions.

Before infrastructure is removed, an operator needs evidence that the application and its data have been preserved, that backups are accessible independently of the original infrastructure, and that recovery procedures are technically viable.

**A successful backup is not proof of recoverability. A successful restore test is.**

`recoverable-saas-decommission` is an open-source project focused on making that distinction practical. It combines an operational decommissioning workflow, reusable guidance and a Docker-based MySQL restore verifier.

## Why This Project Exists

It is relatively straightforward to create a database dump, compress an application directory and copy the resulting archives somewhere safe. The more difficult questions come afterwards:

- Can the database dump actually be imported?
- Does the restored database contain the expected schema?
- Can important records be queried successfully?
- Are the backups accessible without the original server?
- Have application files, uploaded documents and configuration dependencies been preserved?
- Are encryption keys and recovery credentials retained securely?
- Is there sufficient recovery evidence to justify deleting the infrastructure?

A backup may exist and still be unusable, incomplete or dependent on the infrastructure being decommissioned. This project provides a structured way to reduce those risks.

## The Decommissioning Workflow

The recommended process follows nine stages:

```text
Inventory
    |
    v
Archive
    |
    v
Protect
    |
    v
Transfer Off-Server
    |
    v
Verify Integrity
    |
    v
Restore Independently
    |
    v
Inspect Recovered Data
    |
    v
Document Recovery
    |
    v
Decommission
```

Each stage should produce evidence that supports the decision to proceed to the next. In particular, production infrastructure should not be permanently removed simply because a backup command completed successfully.

## MySQL Restore Verification

The repository includes `mysql/verify-restore.sh`, a Bash-based verifier that uses a disposable MySQL 8.0 Docker container.

It performs the following operations:

1. Validates the supplied backup file and required dependencies.
2. Starts a temporary MySQL container with no published ports and Docker networking disabled.
3. Waits for an authenticated MySQL connection.
4. Imports the SQL backup.
5. Confirms that the restored database contains base tables.
6. Optionally executes an application-specific SQL assertions file.
7. Reports PASS or FAIL.
8. Removes the container it created.

The verifier accepts a SQL backup path and an optional assertions file. It has been successfully tested with the included synthetic `.sql` fixture. Compressed-dump testing is still outstanding; do not treat `.sql.gz` support as validated until that test is completed.

### Quick Start

**Linux or Ubuntu WSL**, from the repository root:

```bash
bash mysql/verify-restore.sh fixtures/sample-schema.sql mysql/verification-queries.sql
```

**Windows PowerShell**, with Docker Desktop running and WSL integration enabled for Ubuntu:

```powershell
wsl -d Ubuntu -- bash mysql/verify-restore.sh fixtures/sample-schema.sql mysql/verification-queries.sql
```

The Windows command assumes the current PowerShell directory is the repository root and the WSL distribution is named `Ubuntu`. A separate PowerShell verification script is **not** included; Windows users run the tested Bash implementation through WSL.

Expected successful output includes:

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

The reported count of three tables belongs solely to the **fictional sample fixture**, not to any real SaaS database.

### Verify Your Own Backup

```bash
bash mysql/verify-restore.sh /path/to/backup.sql /path/to/your-assertions.sql
```

The second argument is optional. Without custom assertions, verification is limited to import success and the verifier's built-in structural check. The supplied `mysql/verification-queries.sql` is written specifically for `fixtures/sample-schema.sql`; it must not be treated as a universal production verification suite.

For complete prerequisites, Windows/WSL troubleshooting, security considerations and verification limits, read the **[MySQL Restore Verification Guide](docs/mysql-restore-verification.md)**.

### Verification Levels

| Verification | What it establishes |
| --- | --- |
| Import verification | The SQL dump can be imported without reported errors. |
| Structural verification | The restored database contains base tables; any more specific schema checks must be supplied as assertions. |
| Data verification | Supplied application-specific SQL assertions pass, if provided. |

A successful import does not prove that every production record has been recovered. Full source-to-restore comparison requires trustworthy source baselines or additional application-specific checks.

### Tests Performed

The Bash verifier has been exercised using Windows PowerShell, Ubuntu WSL and Docker Desktop:

| Scenario | Observed result |
| --- | --- |
| Valid synthetic SQL dump with assertions | PASS; imported, checked and cleaned up. |
| Missing backup file | Rejected during input validation. |
| Deliberately failing SQL assertion | Reported FAIL and removed the temporary container. |

Compressed SQL backup testing, intentionally malformed SQL testing and native Linux host testing remain outstanding. No automated CI test suite or machine-readable report is claimed at this stage.

## Security Principles

The tooling is designed around the following principles:

- **Isolation:** The test database has no published network ports, and Docker networking is disabled.
- **No production database connection:** Testing operates on a supplied backup file.
- **Credential protection:** Production credentials and secrets must not be embedded in scripts or committed to version control.
- **Controlled cleanup:** The verifier removes the temporary container it creates, rather than unrelated containers.
- **Explicit verification:** Import errors and failed assertions produce failure results.
- **Minimal data exposure:** Verification output should avoid personal or confidential records.
- **Independent storage:** Recovery archives should remain accessible after the original infrastructure is gone.

Docker isolation reduces exposure but does **not** make untrusted SQL dumps safe to execute. Use backups you are authorised to handle, on a host with appropriate controls. Operators remain responsible for protecting archives, encryption keys, credentials and restored data.

The verifier does not replace backup encryption, integrity checking, access-control review, retention management or an organisation's disaster-recovery policies.

## What This Project Does Not Promise

A successful MySQL restore test is not equivalent to a full application disaster-recovery exercise.

Restoring a complete SaaS platform may also require:

- Application source code and dependencies
- Application encryption keys and environment configuration
- Uploaded documents and persistent storage
- Web server and PHP runtime configuration
- Queue workers and scheduled tasks
- DNS and TLS configuration
- Third-party services and integrations
- Application-level functionality and security testing

The verifier checks a **database restoration**, not full application availability, recovery time objectives or business continuity readiness.

## Background

This project grew out of a real-world Laravel SaaS infrastructure decommissioning exercise involving:

- Ubuntu and Nginx
- PHP and Laravel
- DigitalOcean infrastructure
- Managed MySQL
- OpenSSL-encrypted archives
- SCP transfers and SHA-256 integrity checks
- Windows PowerShell and Ubuntu WSL
- Docker-based MySQL recovery testing
- Infrastructure and DNS decommissioning

The original recovery exercise included creating and protecting application and database archives, transferring encrypted archives to independent storage, comparing cryptographic checksums, restoring a database backup into an isolated Docker environment, inspecting recovered structure and representative records, and documenting recovery requirements before decommissioning.

**A complete clean-room deployment of the application stack was not performed.** The public repository contains synthetic test data and reusable tooling, not production backups or sensitive configuration.

## Repository Status

**Status: Working initial Bash implementation; documentation and validation in progress.**

Available now:

- `mysql/verify-restore.sh` — Docker-based MySQL restore verifier
- `mysql/verification-queries.sql` — SQL assertions for the synthetic fixture
- `fixtures/sample-schema.sql` — fictional database for repeatable demonstrations
- `docs/mysql-restore-verification.md` — usage, prerequisites and limitations

Further work may include broader fixture coverage, automated testing, additional operational templates, structured reporting and an anonymised case study. These are **future possibilities**, not implemented functionality.

Until the remaining validation and security review are complete, treat the tool as an early-stage operational aid rather than a certified recovery solution.

## Intended Audience

- Laravel and PHP developers
- SaaS application owners
- Linux system administrators
- DevOps and infrastructure engineers
- Database administrators
- Technical teams retiring or migrating hosted applications

The concepts apply beyond Laravel, although the originating case study involved a Laravel SaaS environment.

## Project Philosophy

The objective is not to build a large framework for infrastructure management. It is to provide focused, understandable tools that help operators answer one question:

**Can the data and application assets we intend to preserve actually support recovery after the original infrastructure is removed?**

The project prioritises reproducible verification, clear failure reporting, safe defaults, minimal external dependencies, practical cross-platform use, evidence-based decisions and honest documentation of limitations.

## Guiding Principle

> Don't test whether you can create a backup. Test whether you can restore from it.

The objective is not simply to produce an archive. It is to establish documented evidence that important application data can be recovered before the infrastructure holding the original copy is permanently removed.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
