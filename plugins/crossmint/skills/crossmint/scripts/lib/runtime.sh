#!/usr/bin/env bash
# Shared runtime for wallet.sh and x402.sh.
# Sourced (not executed). Sets env vars and ensures the persistent node_modules
# cache at ~/.cache/crossmint-skill/ has the SDK + x402 deps installed.

set -euo pipefail

CMS_CONFIG_FILE="${HOME}/.config/crossmint/.env"
CMS_RUNTIME_DIR="${HOME}/.cache/crossmint-skill"

# --- 1. config sanity -----------------------------------------------------
if [[ ! -f "${CMS_CONFIG_FILE}" ]]; then
  echo "FAIL: ${CMS_CONFIG_FILE} missing. Run scripts/setup.sh first." >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "${CMS_CONFIG_FILE}"; set +a

# Backward-compat: prefer the explicit *_SERVER_API_KEY var; fall back to legacy alias.
: "${CROSSMINT_SERVER_API_KEY:=${CROSSMINT_API_KEY:-}}"
export CROSSMINT_SERVER_API_KEY

if [[ -z "${CROSSMINT_SERVER_API_KEY}" ]]; then
  echo "FAIL: no server-side API key in ${CMS_CONFIG_FILE}." >&2
  echo "      Re-run scripts/setup.sh with --server-key sk_... or --api-key sk_..." >&2
  exit 1
fi

if [[ -z "${CROSSMINT_SIGNER_SECRET:-}" ]]; then
  echo "FAIL: CROSSMINT_SIGNER_SECRET missing in ${CMS_CONFIG_FILE}." >&2
  exit 1
fi

# Default chain for any script that doesn't override.
if [[ "${CROSSMINT_ENV:-staging}" == "production" ]]; then
  : "${CMS_DEFAULT_CHAIN:=base}"
else
  : "${CMS_DEFAULT_CHAIN:=base-sepolia}"
fi
export CMS_DEFAULT_CHAIN

# --- 2. runtime cache -----------------------------------------------------
mkdir -p "${CMS_RUNTIME_DIR}"

if [[ ! -f "${CMS_RUNTIME_DIR}/package.json" ]]; then
  ( cd "${CMS_RUNTIME_DIR}" && npm init -y >/dev/null 2>&1 )
fi

# Idempotent install — only install missing packages.
needed_pkgs=(
  "@crossmint/wallets-sdk"
  "@x402/core"
  "@x402/evm"
  "viem"
)

missing_pkgs=()
for pkg in "${needed_pkgs[@]}"; do
  if [[ ! -d "${CMS_RUNTIME_DIR}/node_modules/${pkg}" ]]; then
    missing_pkgs+=("${pkg}")
  fi
done

if (( ${#missing_pkgs[@]} > 0 )); then
  echo "Bootstrapping crossmint-skill runtime (one-time per package): ${missing_pkgs[*]}" >&2
  ( cd "${CMS_RUNTIME_DIR}" && npm install --silent --no-fund --no-audit "${missing_pkgs[@]}" >/dev/null 2>&1 ) || {
    echo "FAIL: npm install failed in ${CMS_RUNTIME_DIR}." >&2
    echo "      Try: cd ${CMS_RUNTIME_DIR} && npm install ${missing_pkgs[*]}" >&2
    exit 1
  }
fi

export CMS_RUNTIME_DIR

# Helper to invoke a Node ESM script with the runtime cache resolved.
# Node ESM resolves bare imports relative to the script's own location, NOT cwd
# or NODE_PATH. So we copy the script into ${CMS_RUNTIME_DIR} (next to its
# node_modules) on each call. Cheap, no caching/staleness issues.
cms_run_node() {
  local script="$1"; shift
  local script_name; script_name="$(basename "${script}")"
  cp "${script}" "${CMS_RUNTIME_DIR}/${script_name}"
  ( cd "${CMS_RUNTIME_DIR}" && node "$@" "./${script_name}" )
}
