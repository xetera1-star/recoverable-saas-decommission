
# Recoverable SaaS Decommission

**Practical tools and operational guidance for decommissioning SaaS applications without losing the ability to restore them.**

Decommissioning an application involves more than shutting down servers, deleting databases and cancelling hosting subscriptions.

Before infrastructure is removed, an operator needs evidence that the application and its data have been preserved, that the backups are accessible independently of the original infrastructure, and that recovery procedures are technically viable.

**A successful backup is not proof of recoverability. A successful restore test is.**

`recoverable-saas-decommission` is an open-source project focused on making that distinction practical.

It combines an operational decommissioning workflow, reusable documentation and Docker-based MySQL restore-verification tooling.

## Why This Project Exists

It is relatively straightforward to create a database dump, compress an application directory and copy the resulting archives somewhere safe.

The more difficult questions come afterwards:

- Can the database dump actually be imported?
- Does the restored database contain the expected schema?
- Can important records be queried successfully?
- Are the backups accessible without the original server?
- Have application files, uploaded documents and configuration dependencies been preserved?
- Are encryption keys and recovery credentials retained securely?
- Is there sufficient recovery evidence to justify deleting the infrastructure?

A backup may exist and still be unusable, incomplete or dependent on the very infrastructure being decommissioned.

This project provides a structured way to reduce those risks.

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

Each stage should produce evidence that supports the decision to proceed to the next.

In particular, production infrastructure should not be permanently removed simply because a backup command completed successfully.

## MySQL Restore Verification

The project's first executable capability is a Docker-based MySQL restore verifier.

The intended workflow is to:

1. Validate the supplied SQL dump and required dependencies.
2. Create a disposable, isolated MySQL container.
3. Wait until MySQL is ready to accept connections.
4. Import the database dump.
5. Check the restored database structure.
6. Execute optional application-specific verification queries.
7. Produce a clear verification report.
8. Remove the temporary environment safely.

The initial supported backup formats are planned to be:

- `.sql`
- `.sql.gz`

Both Bash and PowerShell entry points are planned, with consistent verification behaviour and reporting.

### Verification Levels

The tool will distinguish between three verification levels:

| Verification | What it establishes |
|---|---|
| Import verification | The SQL dump can be imported without reported errors |
| Structural verification | Expected schema objects exist in the restored database |
| Data verification | Supplied assertions against restored records pass |

A successful import does not automatically prove that every production record has been recovered.

Full source-to-restore comparison requires appropriate source baselines or additional application-specific verification.

## Security Principles

The tooling is designed around the following principles:

- **Isolation:** Test databases should not be exposed through published network ports.
- **No production access required:** Recovery testing should operate on backup files, not production database connections.
- **Credential protection:** Passwords and sensitive values should not be hardcoded into scripts or committed to version control.
- **Controlled cleanup:** Scripts must remove only resources they created.
- **Explicit verification:** Import errors and failed assertions must produce actionable failures.
- **Minimal data exposure:** Verification reports should avoid including personal or confidential records.
- **Independent storage:** Recovery archives should exist outside the infrastructure being decommissioned.

Operators remain responsible for protecting their backup files, encryption keys and application secrets.

The restore-verification tooling is not a substitute for an organisation's backup security, access-control or disaster-recovery policies.

## What This Project Does Not Promise

A successful MySQL restore test is not equivalent to a full application disaster-recovery exercise.

Restoring a complete SaaS platform may also require:

- Application source code and dependency installation
- Application encryption keys and environment configuration
- Uploaded documents and persistent storage
- Web server and PHP runtime configuration
- Queue workers and scheduled tasks
- DNS and TLS configuration
- Third-party services and integrations
- Application-level functionality and security testing

This project provides recovery verification and decommissioning guidance.

It does not certify that an entire application can be reconstructed solely because its database imports successfully.

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

The database recovery workflow was tested independently of the original hosting environment.

The recovery exercise included:

- Creating and protecting application and database archives
- Transferring encrypted archives to independent storage
- Comparing cryptographic checksums between source and destination
- Restoring a MySQL backup into an isolated Docker environment
- Inspecting the restored database structure
- Running representative queries against recovered records
- Removing the temporary test environment
- Documenting restoration requirements before decommissioning

A complete clean-room deployment of the application stack was not part of that exercise.

The reusable tooling in this repository is being developed from the operational lessons of that work, using synthetic test data rather than production records.

## Repository Status

**Status: Initial development**

The operational design is established, but the public verification scripts, automated tests and reporting interfaces are not yet available.

The repository will be developed and tested incrementally before a stable release is published.

Planned deliverables include:

- Docker-based MySQL restore verification
- Bash and PowerShell entry points
- Synthetic SQL fixtures
- Machine-readable verification reports
- Infrastructure inventory and recovery templates
- Security and decommissioning guidance
- An anonymised operational case study

Documentation, examples and tooling will be updated as the implementation progresses.

Until the verifier has been implemented and tested, this repository should not be relied upon as an automated recovery-verification solution.

## Intended Audience

This project is intended for:

- Laravel and PHP developers
- SaaS application owners
- Linux system administrators
- DevOps and infrastructure engineers
- Database administrators
- Technical teams retiring or migrating hosted applications

The concepts are applicable beyond Laravel, although the originating case study involves a Laravel SaaS environment.

## Project Philosophy

The objective is not to build a large framework for infrastructure management.

It is to provide focused, understandable tools that help operators answer a specific question:

**Can the data and application assets we intend to preserve actually support recovery after the original infrastructure is removed?**

The project prioritises:

- Reproducible verification
- Clear failure reporting
- Safe defaults
- Minimal external dependencies
- Cross-platform usability where practical
- Evidence-based decommissioning decisions
- Honest documentation of verification limitations

A verification result should explain what was tested, what passed, what failed and what remains unverified.

## Guiding Principle

> Don't test whether you can create a backup. Test whether you can restore from it.

The objective is not simply to produce an archive.

It is to establish sufficient, documented evidence that important application data can be recovered before the infrastructure holding the original copy is permanently removed.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
