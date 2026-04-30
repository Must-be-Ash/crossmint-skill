# Autonomous recipes — env-aware curl/Node, runnable inline by the agent

> Use these when the agent itself is the actor (mode = AUTO). All snippets read config from `~/.config/crossmint/.env`. Run `scripts/setup.sh` first if the env file doesn't exist; run `scripts/doctor.sh` to verify it.

## Loading config

Every snippet starts with this. The agent runs it via Bash, the env vars become available to the rest of the shell session.

```bash
set -a
source "${HOME}/.config/crossmint/.env"
set +a
# Now $CROSSMINT_API_KEY, $CROSSMINT_SIGNER_SECRET, $CROSSMINT_ENV, $CROSSMINT_API_HOST are set.
```

Or one-shot per command:

```bash
( set -a; source "${HOME}/.config/crossmint/.env"; set +a; <command using $CROSSMINT_API_KEY> )
```

---

## Management API (read-only — safe to call without confirmation)

### List my agents
```bash
curl -s -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/agents" | jq .
```

### List my saved payment methods
```bash
curl -s -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/payment-methods" | jq .
```

### List my virtual cards (order intents)
```bash
curl -s -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/order-intents" | jq .
```

### Get a specific virtual card by id
```bash
curl -s -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/order-intents/${ORDER_INTENT_ID}" | jq .
```

### Get enrollment status of a payment method
```bash
curl -s -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/payment-methods/${PAYMENT_METHOD_ID}/agentic-enrollment" | jq .
```

---

## Management API (mutations — confirm with the user first)

### Create a new agent
```bash
curl -s -X POST \
  -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  -H "Content-Type: application/json" \
  "${CROSSMINT_API_HOST}/api/unstable/agents" \
  -d '{"metadata":{"name":"Claude session agent","description":"Created from the crossmint skill"}}' | jq .
```

### Delete an agent
```bash
curl -s -X DELETE \
  -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/agents/${AGENT_ID}" | jq .
```

### Delete a payment method
```bash
curl -s -X DELETE \
  -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/payment-methods/${PAYMENT_METHOD_ID}" | jq .
```

### Get virtual card credentials (merchant-scoped — needed to actually use the card)
> Source: `references/api/get-virtual-card-credentials.md`. Required scope: `order-intents.credentials`. The order intent must be in `phase: "active"`.

```bash
curl -s -X POST \
  -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  -H "Content-Type: application/json" \
  "${CROSSMINT_API_HOST}/api/unstable/order-intents/${ORDER_INTENT_ID}/credentials" \
  -d '{"merchant":{"name":"Whole Foods","url":"https://www.wholefoodsmarket.com","countryCode":"US"}}' | jq .
```

---

## Wallets — server-side via the SDK

The wallets SDK is JS-only. The agent runs Node inline. **Source-of-truth for the SDK shape: `references/server-signer.md`.** The shape is `recovery + alias`, NOT `signer + owner`. Trust this snippet; do not invent fields.

### Create a server agent wallet

```bash
mkdir -p /tmp/crossmint-scratch && cd /tmp/crossmint-scratch
[ -f package.json ] || npm init -y >/dev/null 2>&1
npm i @crossmint/wallets-sdk >/dev/null 2>&1

cat > create-server-wallet.mjs <<'EOF'
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);

const chain = process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia";
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";

const wallet = await wallets.createWallet({
  chain,
  recovery: { type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET },
  alias,
});

console.log(JSON.stringify({ address: wallet.address, chain, alias }, null, 2));
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  WALLET_ALIAS="claude-agent-wallet" node create-server-wallet.mjs )
```

> `alias` is your handle for `getWallet` later — pick something meaningful and persist it. Wallet creation with the same `alias` + project + chain is idempotent.

### Retrieve an existing wallet by alias

```bash
cat > get-server-wallet.mjs <<'EOF'
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);

const chain = process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia";
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";

const wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain });
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });

console.log(JSON.stringify({ address: wallet.address, chain, alias }, null, 2));
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  WALLET_ALIAS="claude-agent-wallet" node get-server-wallet.mjs )
```

### Check balance

```bash
cat > balance.mjs <<'EOF'
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);

const chain = process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia";
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";

const wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain });
const { nativeToken, tokens } = await wallet.balances(["usdc", "usdxm"]);

console.log(JSON.stringify({ native: nativeToken, tokens }, null, 2));
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  WALLET_ALIAS="claude-agent-wallet" node balance.mjs )
```

> Source: `references/wallet-actions/check-balances.md`. No mutation — safe to run without confirmation.

### Funding a staging wallet — pick by use case

**Decision tree** (full table in `references/funding-staging-wallets.md`):

- Will the wallet pay an **x402 / MPP / Worldstore** endpoint, or test real-USDC code paths? → fund with **base-sepolia USDC** via [Circle's faucet](https://faucet.circle.com/). No auth required. Tell the user verbatim:
  > Go to https://faucet.circle.com/ — paste this address, pick **Base Sepolia**, request USDC.
  > Address: `0xYOUR_WALLET_ADDRESS`
  > Tell me when it's done; I'll re-check the balance.
- Will the wallet only move money between Crossmint wallets (self-contained demo)? → run `wallet.stagingFund(10)` to mint **USDXM** in one call. **USDXM does not work for x402.**

### `wallet.stagingFund(amount)` — USDXM only, staging only

Use only when you don't need an external endpoint to accept the token.

```bash
cat > stagingFund.mjs <<'EOF'
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";
const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);
const wallet = await wallets.getWallet(
  `evm:alias:${process.env.WALLET_ALIAS}`,
  { chain: "base-sepolia" }
);
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });
await wallet.stagingFund(Number(process.env.AMOUNT || "10"));
console.log("Funded.");
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  [ "$CROSSMINT_ENV" = staging ] || { echo "stagingFund only works in staging"; exit 1; }; \
  WALLET_ALIAS="claude-agent-wallet" AMOUNT=10 node stagingFund.mjs )
```

### Send USDC

> **Confirm with the user first** — show recipient, token, amount, and chain. Mutating action.

```bash
cat > send.mjs <<'EOF'
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);

const chain = process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia";
const wallet = await wallets.getWallet(
  `evm:alias:${process.env.WALLET_ALIAS}`,
  { chain }
);
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });

const tx = await wallet.send(
  process.env.RECIPIENT,
  process.env.TOKEN || "usdc",
  process.env.AMOUNT
);

console.log(JSON.stringify({ hash: tx.hash, explorer: tx.explorerLink }, null, 2));
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  WALLET_ALIAS="claude-agent-wallet" \
  RECIPIENT="0xRECIPIENT" \
  TOKEN="usdc" \
  AMOUNT="0.50" \
  node send.mjs )
```

### Sign an EIP-712 typed data payload (e.g. for x402)

```bash
cat > sign-typed.mjs <<'EOF'
import { createCrossmint, CrossmintWallets, EVMWallet } from "@crossmint/wallets-sdk";
const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);
const wallet = await wallets.getWallet(
  `evm:alias:${process.env.WALLET_ALIAS}`,
  { chain: "base-sepolia" }
);
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });

const evm = EVMWallet.from(wallet);
const typedData = JSON.parse(process.env.TYPED_DATA);
const { signature } = await evm.signTypedData(typedData);
console.log(signature);
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  WALLET_ALIAS="claude-agent-wallet" \
  TYPED_DATA='{"types":{...},"primaryType":"...","domain":{...},"message":{...}}' \
  node sign-typed.mjs )
```

### List recent transfers

```bash
( set -a; source "${HOME}/.config/crossmint/.env"; set +a;
curl -s -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  "${CROSSMINT_API_HOST}/api/unstable/wallets/${WALLET_LOCATOR}/transfers?chain=base-sepolia&tokens=usdc&limit=10" \
  | jq . )
```

`WALLET_LOCATOR` can be the address (`0x…`) or `email:user@example.com:evm` or `evm:alias:claude-agent-wallet`.

### More verbs
The full surface (sign-message, send-transaction with calls array, add-signers with prepareOnly, etc.) lives in `references/wallet-actions/*.md`. Each guide has a SDK + REST snippet you can lift.

---

## x402 — pay an HTTP 402 endpoint inline

```bash
mkdir -p /tmp/crossmint-x402 && cd /tmp/crossmint-x402
[ -f package.json ] || npm init -y >/dev/null 2>&1
npm i @crossmint/wallets-sdk @x402/core @x402/evm viem >/dev/null 2>&1

cat > pay.mjs <<'EOF'
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";
import { x402Client, x402HTTPClient, wrapFetchWithPayment } from "@x402/core/client";
import { ExactEvmScheme } from "@x402/evm/exact/client";

const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);
const wallet = await wallets.getWallet(process.env.WALLET_ADDRESS, { chain: "base" });

await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });

const x402Signer = {
  address: wallet.address,
  async signTypedData(typedData) {
    const { signature } = await wallet.signTypedData({ ...typedData, chain: "base" });
    return signature;
  },
};

const client = new x402Client();
client.register("eip155:*", new ExactEvmScheme(x402Signer));
const fetchPay = wrapFetchWithPayment(fetch, client);

const res = await fetchPay(process.env.TARGET_URL, { method: "GET" });
console.log("status:", res.status);
console.log("body:", await res.text());

if (res.ok) {
  const httpClient = new x402HTTPClient(client);
  console.log("receipt:", httpClient.getPaymentSettleResponse((n) => res.headers.get(n)));
}
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  WALLET_ADDRESS="0x..." TARGET_URL="https://api.example.com/protected" node pay.mjs )
```

> Source: `references/x402.md`. Confirm the URL and the wallet's USDC balance with the user before running — this spends real money on the first 402 negotiation.

---

## Worldstore — autonomous Amazon order

Source: `references/inventory.md`. Confirm recipient + ASIN + amount with the user before submitting.

```bash
( set -a; source "${HOME}/.config/crossmint/.env"; set +a;
curl -s -X POST \
  -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  -H "Content-Type: application/json" \
  "${CROSSMINT_API_HOST}/api/2022-06-09/orders" \
  -d '{
    "recipient": {
      "email": "REPLACE@example.com",
      "physicalAddress": {
        "name": "REPLACE",
        "line1": "REPLACE",
        "city": "REPLACE",
        "state": "REPLACE",
        "postalCode": "REPLACE",
        "country": "US"
      }
    },
    "locale": "en-US",
    "payment": {
      "receiptEmail": "REPLACE@example.com",
      "method": "'"$( [ "$CROSSMINT_ENV" = production ] && echo base || echo base-sepolia )"'",
      "currency": "usdc",
      "payerAddress": "0x..."
    },
    "lineItems": [{ "productLocator": "amazon:B00O79SKV6" }]
  }' | jq . )
```

---

## Safety rules — burned into every recipe

- **No mutating call without explicit user confirmation of the exact action.** Show them the destination, amount, and the curl command you're about to run, then wait.
- **Always check `jq` is available** before piping — fall back to raw JSON if not (`command -v jq >/dev/null || echo 'install jq for pretty output'`).
- **Never echo `$CROSSMINT_API_KEY` or `$CROSSMINT_SIGNER_SECRET` to the conversation.** They live in `~/.config/crossmint/.env` precisely so the user never has to re-type them.
- **One-shot env loading.** Use `( set -a; source ...; set +a; <cmd> )` so env vars don't leak into later, unrelated Bash calls in the same session.
