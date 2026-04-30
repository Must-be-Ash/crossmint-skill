#!/usr/bin/env bash
# Crossmint skill — config doctor.
# Verifies ~/.config/crossmint/.env exists, loads it, and pings a free read endpoint.
# Exits non-zero with a clear message on any failure so the agent can recover.

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

echo "OK:   config present at ${ENV_FILE}"
echo "      env=${CROSSMINT_ENV}   host=${CROSSMINT_API_HOST}"

# Reachability probe — list agents (read-only, scope: agents.read)
URL="${CROSSMINT_API_HOST}/api/unstable/agents"
echo "Probe: GET ${URL}"

http_code=$(curl -s -o /tmp/crossmint-doctor.out -w "%{http_code}" \
  -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${URL}" || echo "000")

case "${http_code}" in
  200)
    echo "OK:   API key works (HTTP 200). Response is in /tmp/crossmint-doctor.out"
    exit 0
    ;;
  401|403)
    echo "FAIL: API key rejected (HTTP ${http_code})."
    echo "      Check the key has the 'agents.read' scope and matches the ${CROSSMINT_ENV} environment."
    cat /tmp/crossmint-doctor.out
    exit 1
    ;;
  000)
    echo "FAIL: could not reach ${CROSSMINT_API_HOST}. Network or DNS issue?"
    exit 1
    ;;
  *)
    echo "WARN: unexpected HTTP ${http_code} from ${URL}."
    cat /tmp/crossmint-doctor.out
    exit 1
    ;;
esac
