#!/usr/bin/env bash
# Crossmint skill — first-run setup wizard.
# Writes ~/.config/crossmint/.env with API keys (server, client, or both) + auto-generated signer secret.
# Re-runnable; will overwrite an existing config only with explicit confirmation from the caller.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/crossmint"
ENV_FILE="${CONFIG_DIR}/.env"

mkdir -p "${CONFIG_DIR}"
chmod 700 "${CONFIG_DIR}"

# --- args -----------------------------------------------------------------
SERVER_KEY=""
CLIENT_KEY=""
LEGACY_KEY=""              # --api-key for backward compat; auto-routed by prefix
ENVIRONMENT="staging"
FORCE=0
SIGNER_SECRET=""

usage() {
  cat <<USAGE
Usage: setup.sh [--server-key sk_...] [--client-key ck_...] [--api-key <key>] [--env staging|production] [--signer-secret xmsk1_...] [--force]

Provide whichever keys you have. You can supply BOTH server and client; the agent will route to the right one per call.

  --server-key      Crossmint SERVER-side key (sk_*). Used for: wallet creation, x402 / MPP payments,
                    Worldstore orders, all autonomous wallet ops.
  --client-key      Crossmint CLIENT-side key (ck_*). Used for: cards stack — list/create/delete agents,
                    payment methods, virtual cards (order intents), agentic enrollments.
  --api-key         Backward-compat: a single key. Auto-routed by prefix (sk_* → server, ck_* → client).
                    Equivalent to --server-key OR --client-key depending on what you paste.
  --env             staging (default) or production. Determines API host.
  --signer-secret   Optional. Provide your own xmsk1_<64-hex>. If omitted, a fresh one is generated.
  --force           Overwrite an existing ~/.config/crossmint/.env without prompting.

Get keys at:
  staging    https://staging.crossmint.com/console/projects/apiKeys
  production https://www.crossmint.com/console/projects/apiKeys
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-key) SERVER_KEY="$2"; shift 2 ;;
    --client-key) CLIENT_KEY="$2"; shift 2 ;;
    --api-key) LEGACY_KEY="$2"; shift 2 ;;
    --env) ENVIRONMENT="$2"; shift 2 ;;
    --signer-secret) SIGNER_SECRET="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

# Route --api-key by prefix into the right slot.
if [[ -n "${LEGACY_KEY}" ]]; then
  case "${LEGACY_KEY}" in
    sk_*) [[ -z "${SERVER_KEY}" ]] && SERVER_KEY="${LEGACY_KEY}" || { echo "ERROR: both --server-key and --api-key (sk_*) provided." >&2; exit 2; } ;;
    ck_*) [[ -z "${CLIENT_KEY}" ]] && CLIENT_KEY="${LEGACY_KEY}" || { echo "ERROR: both --client-key and --api-key (ck_*) provided." >&2; exit 2; } ;;
    *)    echo "ERROR: --api-key must start with sk_ or ck_ (got '${LEGACY_KEY:0:5}...')." >&2; exit 2 ;;
  esac
fi

if [[ -z "${SERVER_KEY}" && -z "${CLIENT_KEY}" ]]; then
  echo "ERROR: provide at least one of --server-key, --client-key, or --api-key." >&2
  usage
  exit 2
fi

# Validate prefixes
[[ -n "${SERVER_KEY}" && "${SERVER_KEY:0:3}" != "sk_" ]] && { echo "ERROR: --server-key must start with sk_ (got '${SERVER_KEY:0:5}...')." >&2; exit 2; }
[[ -n "${CLIENT_KEY}" && "${CLIENT_KEY:0:3}" != "ck_" ]] && { echo "ERROR: --client-key must start with ck_ (got '${CLIENT_KEY:0:5}...')." >&2; exit 2; }

case "${ENVIRONMENT}" in
  staging|production) ;;
  *) echo "ERROR: --env must be 'staging' or 'production' (got '${ENVIRONMENT}')" >&2; exit 2 ;;
esac

if [[ -f "${ENV_FILE}" && "${FORCE}" -ne 1 ]]; then
  echo "ERROR: ${ENV_FILE} already exists. Re-run with --force to overwrite." >&2
  echo "       To add a missing key non-destructively, see scripts/setup.sh --help and use --force with all keys you want." >&2
  exit 3
fi

# --- signer secret --------------------------------------------------------
if [[ -z "${SIGNER_SECRET}" ]]; then
  HEX=$(openssl rand -hex 32)
  SIGNER_SECRET="xmsk1_${HEX}"
fi
[[ "${SIGNER_SECRET}" =~ ^xmsk1_[0-9a-f]{64}$ ]] || { echo "ERROR: signer secret must match xmsk1_<64-hex>." >&2; exit 2; }

# --- host -----------------------------------------------------------------
if [[ "${ENVIRONMENT}" == "staging" ]]; then
  API_HOST="https://staging.crossmint.com"
else
  API_HOST="https://www.crossmint.com"
fi

# --- write env file -------------------------------------------------------
umask 077
{
  echo "# Crossmint skill config — managed by scripts/setup.sh"
  echo "# Do not commit this file. Permissions are 600 by default."
  echo
  [[ -n "${SERVER_KEY}" ]] && echo "CROSSMINT_SERVER_API_KEY=${SERVER_KEY}"
  [[ -n "${CLIENT_KEY}" ]] && echo "CROSSMINT_CLIENT_API_KEY=${CLIENT_KEY}"
  echo
  echo "# Backward-compat alias for older recipes that still read CROSSMINT_API_KEY."
  echo "# Points at whichever key was provided first; agent should prefer the explicit"
  echo "# CROSSMINT_SERVER_API_KEY / CROSSMINT_CLIENT_API_KEY when available."
  if [[ -n "${SERVER_KEY}" ]]; then
    echo "CROSSMINT_API_KEY=${SERVER_KEY}"
  else
    echo "CROSSMINT_API_KEY=${CLIENT_KEY}"
  fi
  echo
  echo "CROSSMINT_SIGNER_SECRET=${SIGNER_SECRET}"
  echo "CROSSMINT_ENV=${ENVIRONMENT}"
  echo "CROSSMINT_API_HOST=${API_HOST}"
  echo "# Default wallet alias the agent uses for get-or-create. Same alias + same"
  echo "# CROSSMINT_SIGNER_SECRET + same project + same chain → same address forever."
  echo "WALLET_ALIAS=claude-agent-wallet"
  echo "SETUP_COMPLETE=true"
} > "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

# --- summary --------------------------------------------------------------
echo "OK: wrote ${ENV_FILE}"
echo "    env=${ENVIRONMENT}   host=${API_HOST}"
echo "    signer secret saved (xmsk1_… 64 hex chars)"
echo "    wallet alias: claude-agent-wallet"
echo
if [[ -n "${SERVER_KEY}" ]]; then
  echo "    [✓] CROSSMINT_SERVER_API_KEY  — wallets, x402, MPP, Worldstore, autonomous ops"
else
  echo "    [ ] CROSSMINT_SERVER_API_KEY  — MISSING. To add later, re-run with --server-key sk_... --force"
fi
if [[ -n "${CLIENT_KEY}" ]]; then
  echo "    [✓] CROSSMINT_CLIENT_API_KEY  — cards, virtual cards, agentic enrollments (with user JWT)"
else
  echo "    [ ] CROSSMINT_CLIENT_API_KEY  — MISSING. To add later, re-run with --client-key ck_... --force"
fi
echo
echo "Next: run scripts/doctor.sh to verify the keys work against the configured environment."
