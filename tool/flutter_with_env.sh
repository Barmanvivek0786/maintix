#!/usr/bin/env bash
set -euo pipefail

# Flutter's --dart-define values are compile-time configuration. This wrapper
# keeps the Supabase anon key in Replit Secrets/CI instead of source control.
if [[ "${1:-}" == "pub" ]]; then
  exec flutter "$@"
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "SUPABASE_ANON_KEY is not configured in the environment." >&2
  echo "Add it as a workspace secret, then rerun this command." >&2
  exit 1
fi

exec flutter "$@" \
  --dart-define="SUPABASE_URL=${SUPABASE_URL:-https://hudlucmsjyjilkjpviva.supabase.co}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"