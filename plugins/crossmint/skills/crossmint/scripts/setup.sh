#!/usr/bin/env bash
# Crossmint skill — first-run setup wizard.
# Writes ~/.config/crossmint/.env with API key + auto-generated signer secret.
# Re-runnable; will overwrite an existing config only with explicit confirmation from the caller.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/crossmint"
ENV_FILE="${CONFIG_DIR}/.env"

mkdir -p "${CONFIG_DIR}"
chmod 700 "${CONFIG_DIR}"

# --- args -----------------------------------------------------------------
API_KEY=""
ENVIRONMENT="staging"
FORCE=0
SIGNER_SECRET=""

usage() {
  cat <<USAGE
Usage: setup.sh --api-key <key> [--env staging|production] [--signer-secret xmsk1_...] [--force]

  --api-key         Crossmint API key. Get one at https://staging.crossmint.com/console/projects/apiKeys
                    (production: https://www.crossmint.com/console/projects/apiKeys).
  --env             staging (default) or production. Determines API host.
  --signer-secret   Optional. Provide your own xmsk1_<64-hex> secret.
                    If omitted, a fresh one is generated for you.
  --force           Overwrite an existing ~/.config/crossmint/.env without prompting.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key) API_KEY="$2"; shift 2 ;;
    --env) ENVIRONMENT="$2"; shift 2 ;;
    --signer-secret) SIGNER_SECRET="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "${API_KEY}" ]]; then
  echo "ERROR: --api-key is required." >&2
  usage
  exit 2
fi

case "${ENVIRONMENT}" in
  staging|production) ;;
  *) echo "ERROR: --env must be 'staging' or 'production' (got '${ENVIRONMENT}')" >&2; exit 2 ;;
esac

if [[ -f "${ENV_FILE}" && "${FORCE}" -ne 1 ]]; then
  echo "ERROR: ${ENV_FILE} already exists. Re-run with --force to overwrite." >&2
  exit 3
fi

# --- signer secret --------------------------------------------------------
if [[ -z "${SIGNER_SECRET}" ]]; then
  # 32 bytes = 64 hex chars
  HEX=$(openssl rand -hex 32)
  SIGNER_SECRET="xmsk1_${HEX}"
fi

if ! [[ "${SIGNER_SECRET}" =~ ^xmsk1_[0-9a-f]{64}$ ]]; then
  echo "ERROR: signer secret must match xmsk1_<64-hex>." >&2
  exit 2
fi

# --- host -----------------------------------------------------------------
if [[ "${ENVIRONMENT}" == "staging" ]]; then
  API_HOST="https://staging.crossmint.com"
else
  API_HOST="https://www.crossmint.com"
fi

# --- write env file -------------------------------------------------------
umask 077
cat > "${ENV_FILE}" <<EOF
# Crossmint skill config — managed by scripts/setup.sh
# Do not commit this file. Permissions are 600 by default.

CROSSMINT_API_KEY=${API_KEY}
CROSSMINT_SIGNER_SECRET=${SIGNER_SECRET}
CROSSMINT_ENV=${ENVIRONMENT}
CROSSMINT_API_HOST=${API_HOST}
SETUP_COMPLETE=true
EOF
chmod 600 "${ENV_FILE}"

echo "OK: wrote ${ENV_FILE}"
echo "    env=${ENVIRONMENT}   host=${API_HOST}"
echo "    signer secret saved (xmsk1_… 64 hex chars)"
echo
echo "Next: run scripts/doctor.sh to verify the API key works."
