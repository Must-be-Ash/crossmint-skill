#!/usr/bin/env bash
# Crossmint skill — wallet operations CLI.
# Subcommands: info | balance | send | transfers | sign

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB_DIR="${SCRIPT_DIR}/lib"

# shellcheck disable=SC1091
source "${LIB_DIR}/runtime.sh"

usage() {
  cat <<USAGE
Usage: wallet.sh <command> [args]

Commands:
  info                                  Get-or-create the default wallet. Prints {address, alias, chain, env, created}.
  balance                               Check USDC (verified on-chain), USDXM, and native ETH. Never fabricates 0s.
  send <recipient> <token> <amount>     Send a token. Echoes the action to stderr before submitting.
                                        Examples:
                                          wallet.sh send 0xabc... usdc 0.50
                                          wallet.sh send vitalik.eth usdc 1.00
  transfers [limit]                     List recent transfers. Default limit 10.
  sign <message>                        EIP-191 sign a plain message.

Reads:
  ~/.config/crossmint/.env  (created by scripts/setup.sh)
    CROSSMINT_SERVER_API_KEY
    CROSSMINT_SIGNER_SECRET
    CROSSMINT_ENV (staging|production)  -> chain (base-sepolia|base)
    WALLET_ALIAS (default: claude-agent-wallet)

Output:
  Stdout: JSON only (pipe to jq).
  Stderr: progress messages, confirmations, errors.
USAGE
}

[[ $# -lt 1 ]] && { usage; exit 2; }
cmd="$1"; shift

case "$cmd" in
  info)
    cms_run_node "${LIB_DIR}/wallet-info.mjs"
    ;;
  balance)
    cms_run_node "${LIB_DIR}/wallet-balance.mjs"
    ;;
  send)
    [[ $# -lt 3 ]] && { echo "Usage: wallet.sh send <recipient> <token> <amount>" >&2; exit 2; }
    RECIPIENT="$1" TOKEN="$2" AMOUNT="$3" cms_run_node "${LIB_DIR}/wallet-send.mjs"
    ;;
  transfers)
    LIMIT="${1:-10}" cms_run_node "${LIB_DIR}/wallet-transfers.mjs"
    ;;
  sign)
    [[ $# -lt 1 ]] && { echo "Usage: wallet.sh sign <message>" >&2; exit 2; }
    MESSAGE="$1" cms_run_node "${LIB_DIR}/wallet-sign.mjs"
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
