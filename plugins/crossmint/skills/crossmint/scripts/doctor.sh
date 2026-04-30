#!/usr/bin/env bash
# Crossmint skill — config doctor.
# Verifies ~/.config/crossmint/.env exists, detects whether the API key is server- or client-side,
# and probes a key-type-appropriate endpoint. Exits non-zero with a clear message on any failure.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/crossmint"
ENV_FILE="${CONFIG_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "FAIL: ${ENV_FILE} does not exist."
  echo "      Run scripts/setup.sh --api-key <key> [--env staging|production] first."
  exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

missing=0
for var in CROSSMINT_API_KEY CROSSMINT_SIGNER_SECRET CROSSMINT_ENV CROSSMINT_API_HOST; do
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

# --- key-type detection ---------------------------------------------------
# Crossmint key prefixes (current as of 2026-04):
#   sk_staging_* / sk_production_*  → server-side
#   ck_staging_* / ck_production_*  → client-side
KEY_TYPE="unknown"
case "${CROSSMINT_API_KEY}" in
  sk_*) KEY_TYPE="server" ;;
  ck_*) KEY_TYPE="client" ;;
esac

echo "OK:   config present at ${ENV_FILE}"
echo "      env=${CROSSMINT_ENV}   host=${CROSSMINT_API_HOST}   key_type=${KEY_TYPE}"

# --- probe ----------------------------------------------------------------
# We pick the endpoint based on the key type so the test actually exercises
# the auth path the user intends to use.
#
#   client key → GET /unstable/agents               (returns 200 with JWT-bound list)
#   server key → GET /api/2025-06-09/wallets/{dummy} (returns 404 if auth passes;
#                                                    401/403 if the key is bad)
#   unknown   → try the server probe; fall back to client.

probe() {
  local url="$1"
  local code
  code=$(curl -s -o /tmp/crossmint-doctor.out -w "%{http_code}" \
           -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
           "${url}" || echo "000")
  echo "${code}"
}

interpret_server() {
  local code="$1"
  case "${code}" in
    200|404) return 0 ;;          # 404 = wallet not found, but auth was accepted
    401|403) return 1 ;;
    000)     return 2 ;;          # network
    *)       return 3 ;;          # unexpected
  esac
}

interpret_client() {
  local code="$1"
  case "${code}" in
    200)     return 0 ;;
    401|403) return 1 ;;
    000)     return 2 ;;
    *)       return 3 ;;
  esac
}

if [[ "${KEY_TYPE}" == "server" ]]; then
  URL="${CROSSMINT_API_HOST}/api/2025-06-09/wallets/evm%3Aalias%3Acrossmint-skill-doctor-probe"
  echo "Probe: GET ${URL}  (server-key probe — wallets API)"
  code=$(probe "${URL}")
  rc=0; interpret_server "${code}" || rc=$?
  case "${rc}" in
    0) echo "OK:   server API key works (HTTP ${code} — auth accepted)."
       exit 0 ;;
    1) echo "FAIL: API key rejected (HTTP ${code})."
       echo "      Check the key is server-side (sk_*) and matches the ${CROSSMINT_ENV} environment."
       cat /tmp/crossmint-doctor.out 2>/dev/null
       exit 1 ;;
    2) echo "FAIL: could not reach ${CROSSMINT_API_HOST}. Network or DNS issue?"
       exit 1 ;;
    *) echo "WARN: unexpected HTTP ${code}."
       cat /tmp/crossmint-doctor.out 2>/dev/null
       exit 1 ;;
  esac
fi

if [[ "${KEY_TYPE}" == "client" ]]; then
  URL="${CROSSMINT_API_HOST}/api/unstable/agents"
  echo "Probe: GET ${URL}  (client-key probe — agents API)"
  code=$(probe "${URL}")
  rc=0; interpret_client "${code}" || rc=$?
  case "${rc}" in
    0) echo "OK:   client API key works (HTTP ${code})."
       exit 0 ;;
    1) echo "FAIL: API key rejected (HTTP ${code})."
       echo "      Check the key is client-side (ck_*) and matches the ${CROSSMINT_ENV} environment."
       cat /tmp/crossmint-doctor.out 2>/dev/null
       exit 1 ;;
    2) echo "FAIL: could not reach ${CROSSMINT_API_HOST}. Network or DNS issue?"
       exit 1 ;;
    *) echo "WARN: unexpected HTTP ${code}."
       cat /tmp/crossmint-doctor.out 2>/dev/null
       exit 1 ;;
  esac
fi

# Unknown key type — try server probe first (covers the most common autonomous case),
# fall back to client.
URL_SERVER="${CROSSMINT_API_HOST}/api/2025-06-09/wallets/evm%3Aalias%3Acrossmint-skill-doctor-probe"
URL_CLIENT="${CROSSMINT_API_HOST}/api/unstable/agents"

code=$(probe "${URL_SERVER}")
rc=0; interpret_server "${code}" || rc=$?
if [[ "${rc}" -eq 0 ]]; then
  echo "OK:   key works as a server-side key (HTTP ${code} on wallets API)."
  exit 0
fi

code=$(probe "${URL_CLIENT}")
rc=0; interpret_client "${code}" || rc=$?
if [[ "${rc}" -eq 0 ]]; then
  echo "OK:   key works as a client-side key (HTTP ${code} on agents API)."
  exit 0
fi

echo "FAIL: key was rejected by both server-key and client-key probes."
echo "      Confirm the key prefix (sk_* server, ck_* client), the environment"
echo "      (${CROSSMINT_ENV}), and that the project has any required scopes enabled."
exit 1
