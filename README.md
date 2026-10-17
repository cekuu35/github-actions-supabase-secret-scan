# GitHub Action: Supabase Secret Scan

A reusable GitHub Actions workflow template that scans pull requests for **leaked Supabase keys** (service role keys, hardcoded JWTs, committed `.env` files) before they reach `main`.

## Why

Supabase `service_role` keys bypass Row Level Security. If one leaks into a PR, anyone with the key has full database access. This action fails the build so the secret never merges.

## What it detects

- Hardcoded Supabase JWTs (`eyJhbGci...`).
- `service_role` / `SERVICE_ROLE` keys assigned inline.
- Committed `.env` / `.env.*` files.
- Supabase project URL and JWT on the same line.

## Quick start

1. Copy `templates/scan-supabase-secrets.yml` to `.github/workflows/scan-supabase-secrets.yml` in your repo, and copy `scripts/scan.sh`.
2. Commit and open a PR — the scan runs automatically.
3. (Optional) Add the workflow to a reusable workflow call for org-wide enforcement.

```yaml
# .github/workflows/scan.yml
name: Secret scan
on: [pull_request]
jobs:
  scan:
    uses: cekuu35/github-actions-supabase-secret-scan/.github/workflows/scan-supabase-secrets.yml@main
```

## Local usage

```bash
bash scripts/scan.sh .
```

## Limitations

- Regex-based; not a full secret scanner. Pair with `gitleaks`/`trufflehog` for broader coverage.
- Does not detect rotated/obfuscated secrets.
- Review false positives before disabling.

## Need a deeper Supabase security review?

This action catches leaks. For a **complete RLS policy audit** (40+ checks, SQL test harness, CI integration, remediation checklist), get the Supabase RLS Audit Kit ($29):

👉 https://cengokurtoglu.gumroad.com/l/supabase-rls-audit-kit

## License

MIT
