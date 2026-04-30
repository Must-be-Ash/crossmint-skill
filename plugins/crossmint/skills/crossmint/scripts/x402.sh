#!/usr/bin/env bash
# Crossmint skill — x402 operations CLI.
# Subcommands: probe | pay

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB_DIR="${SCRIPT_DIR}/lib"

# shellcheck disable=SC1091
source "${LIB_DIR}/runtime.sh"

usage() {
  cat <<USAGE
Usage: x402.sh <command> <url> [args]

Commands:
  probe <url>                Send a no-payment request. If the endpoint returns 402,
                             parse the requirements (version, network, amount, recipient)
                             and print as JSON. Never spends. Always run this BEFORE pay.

  pay   <url> [--max <raw>]  Probe + sign + retry. Pays up to --max raw USDC if set
                             (1000000 = \$1.00). Outputs the response body and decoded
                             on-chain receipt as JSON.

Reads:
  ~/.config/crossmint/.env
    CROSSMINT_SERVER_API_KEY, CROSSMINT_SIGNER_SECRET, CROSSMINT_ENV, WALLET_ALIAS

Output: JSON on stdout. Errors / SDK chatter on stderr.
USAGE
}

[[ $# -lt 1 ]] && { usage; exit 2; }
cmd="$1"; shift

case "$cmd" in
  probe)
    [[ $# -lt 1 ]] && { echo "Usage: x402.sh probe <url>" >&2; exit 2; }
    URL="$1" cms_run_node "${LIB_DIR}/x402-probe.mjs"
    ;;
  pay)
    [[ $# -lt 1 ]] && { echo "Usage: x402.sh pay <url> [--max <raw>]" >&2; exit 2; }
    URL="$1"; shift
    MAX_AMOUNT=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --max) MAX_AMOUNT="$2"; shift 2 ;;
        *) echo "Unknown flag: $1" >&2; exit 2 ;;
      esac
    done
    URL="$URL" MAX_AMOUNT="$MAX_AMOUNT" cms_run_node "${LIB_DIR}/x402-pay.mjs"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac
