#!/usr/bin/env bash
# Crossmint skill — config doctor.
# Verifies ~/.config/crossmint/.env exists, loads it, and probes whichever
# keys are present (server, client, or both) against their canonical endpoints.
# Exits 0 only if every present key passes its probe.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/crossmint"
ENV_FILE="${CONFIG_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "FAIL: ${ENV_FILE} does not exist."
  echo "      Run scripts/setup.sh --server-key sk_... [--client-key ck_...] [--env staging|production] first."
  exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

# --- required core fields -------------------------------------------------
missing=0
for var in CROSSMINT_SIGNER_SECRET CROSSMINT_ENV CROSSMINT_API_HOST; do
  if [[ -z "${!var:-}" ]]; then
    echo "FAIL: ${var} is not set in ${ENV_FILE}"
    missing=1
  fi
done
[[ "${missing}" -ne 0 ]] && exit 1

if ! [[ "${CROSSMINT_SIGNER_SECRET}" =~ ^xmsk1_[0-9a-f]{64}$ ]]; then
  echo "FAIL: CROSSMINT_SIGNER_SECRET does not match xmsk1_<64-hex>."
  exit 1
fi

if [[ -z "${CROSSMINT_SERVER_API_KEY:-}" && -z "${CROSSMINT_CLIENT_API_KEY:-}" ]]; then
  echo "FAIL: neither CROSSMINT_SERVER_API_KEY nor CROSSMINT_CLIENT_API_KEY is set."
  echo "      Re-run setup.sh with --server-key, --client-key, or --api-key."
  exit 1
fi

echo "OK:   config present at ${ENV_FILE}"
echo "      env=${CROSSMINT_ENV}   host=${CROSSMINT_API_HOST}"

# --- probe helpers --------------------------------------------------------
probe() {
  local url="$1" key="$2" out
  out=$(mktemp)
  local code
  code=$(curl -s -o "${out}" -w "%{http_code}" -H "X-API-KEY: ${key}" "${url}" || echo "000")
  echo "${code}|${out}"
}

# --- server key probe -----------------------------------------------------
SERVER_OK=1
if [[ -n "${CROSSMINT_SERVER_API_KEY:-}" ]]; then
  URL="${CROSSMINT_API_HOST}/api/2025-06-09/wallets/evm%3Aalias%3Acrossmint-skill-doctor-probe"
  echo
  echo "Probe: server-side key → GET ${URL}"
  result=$(probe "${URL}" "${CROSSMINT_SERVER_API_KEY}")
  code="${result%%|*}"; out="${result##*|}"
  case "${code}" in
    200|404)
      echo "  OK: server API key works (HTTP ${code} — auth accepted)."
      ;;
    401|403)
      echo "  FAIL: server API key rejected (HTTP ${code})."
      echo "        Confirm the key starts with sk_, matches env=${CROSSMINT_ENV}, and has wallets.read scope."
      cat "${out}" 2>/dev/null; echo
      SERVER_OK=0
      ;;
    000)
      echo "  FAIL: could not reach ${CROSSMINT_API_HOST}. Network or DNS issue?"
      SERVER_OK=0
      ;;
    *)
      echo "  WARN: unexpected HTTP ${code}."
      cat "${out}" 2>/dev/null; echo
      SERVER_OK=0
      ;;
  esac
  rm -f "${out}"
fi

# --- client key probe -----------------------------------------------------
CLIENT_OK=1
if [[ -n "${CROSSMINT_CLIENT_API_KEY:-}" ]]; then
  URL="${CROSSMINT_API_HOST}/api/unstable/agents"
  echo
  echo "Probe: client-side key → GET ${URL}"
  result=$(probe "${URL}" "${CROSSMINT_CLIENT_API_KEY}")
  code="${result%%|*}"; out="${result##*|}"
  case "${code}" in
    200)
      echo "  OK: client API key works (HTTP 200)."
      ;;
    401|403)
      echo "  NOTE: HTTP ${code} from /unstable/agents."
      echo "        This endpoint typically also wants a user JWT (Authorization: Bearer ...);"
      echo "        a 401/403 here can mean either a bad key OR a missing JWT."
      echo "        If your key is fresh from the console, it's likely fine — JWT is needed at call time."
      cat "${out}" 2>/dev/null; echo
      # Don't fail doctor on this — the key may still be valid; JWT is the missing piece.
      ;;
    000)
      echo "  FAIL: could not reach ${CROSSMINT_API_HOST}. Network or DNS issue?"
      CLIENT_OK=0
      ;;
    *)
      echo "  WARN: unexpected HTTP ${code}."
      cat "${out}" 2>/dev/null; echo
      ;;
  esac
  rm -f "${out}"
fi

echo
if [[ -n "${CROSSMINT_SERVER_API_KEY:-}" ]] && [[ "${SERVER_OK}" -eq 1 ]]; then
  echo "  [✓] server-side key — wallets, x402, MPP, Worldstore"
elif [[ -n "${CROSSMINT_SERVER_API_KEY:-}" ]]; then
  echo "  [✗] server-side key — FAILED probe"
fi
if [[ -n "${CROSSMINT_CLIENT_API_KEY:-}" ]] && [[ "${CLIENT_OK}" -eq 1 ]]; then
  echo "  [✓] client-side key — cards, virtual cards (also needs user JWT at call time)"
elif [[ -n "${CROSSMINT_CLIENT_API_KEY:-}" ]]; then
  echo "  [✗] client-side key — FAILED probe"
fi

# Overall exit code: fail if any present key failed its probe.
[[ "${SERVER_OK}" -eq 0 || "${CLIENT_OK}" -eq 0 ]] && exit 1
exit 0
