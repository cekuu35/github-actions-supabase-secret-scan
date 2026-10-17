#!/usr/bin/env bash
# scripts/scan.sh — scan a repository for leaked Supabase secrets.
# Exits non-zero (and prints file:line hits) when a likely leak is found.

set -u

ROOT="${1:-.}"
FAIL=0

# Files/dirs to skip.
EXCLUDES=(
  ".git"
  "node_modules"
  "dist"
  "build"
  ".next"
  "coverage"
)

build_find_args() {
  local args=()
  for d in "${EXCLUDES[@]}"; do
    args+=(-not -path "*/$d/*" -not -name "$d")
  done
  printf '%s\n' "${args[@]}"
}

# 1. Hardcoded JWTs (Supabase anon/service_role keys are JWTs).
mapfile -t jwt_hits < <(grep -RInE 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+' "$ROOT" \
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build \
  --exclude='*.lock' --exclude='*.md' 2>/dev/null || true)

if [ "${#jwt_hits[@]}" -gt 0 ]; then
  echo "Possible hardcoded JWT (Supabase key) found:"
  printf '  %s\n' "${jwt_hits[@]}"
  FAIL=1
fi

# 2. Service role key assigned in source (not via env indirection).
mapfile -t sr_hits < <(grep -RInE '(SERVICE_ROLE|service_role)[[:space:]]*[:=][[:space:]]*["'\'']?eyJ' "$ROOT" \
  --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null || true)

if [ "${#sr_hits[@]}" -gt 0 ]; then
  echo "Service role key appears to be hardcoded:"
  printf '  %s\n' "${sr_hits[@]}"
  FAIL=1
fi

# 3. Committed .env files (should never be in git).
mapfile -t env_hits < <(find "$ROOT" -type f -name '.env' -o -name '.env.*' 2>/dev/null | grep -v node_modules || true)
# Filter to tracked-ish (any present in working tree counts as risk).
if [ "${#env_hits[@]}" -gt 0 ]; then
  echo "Committed .env file(s) detected (review before pushing):"
  printf '  %s\n' "${env_hits[@]}"
  FAIL=1
fi

# 4. Supabase URL + key on same line (common copy-paste leak).
mapfile -t combo_hits < <(grep -RInE 'supabase\.co.*eyJ|eyJ.*supabase\.co' "$ROOT" \
  --exclude-dir=.git 2>/dev/null || true)
if [ "${#combo_hits[@]}" -gt 0 ]; then
  echo "Supabase URL and JWT on the same line:"
  printf '  %s\n' "${combo_hits[@]}"
  FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "Scan FAILED. Remove the secret, rotate it in the Supabase dashboard, and use env vars / secret managers."
  exit 1
fi

echo "Supabase secret scan: no leaks detected."
exit 0
