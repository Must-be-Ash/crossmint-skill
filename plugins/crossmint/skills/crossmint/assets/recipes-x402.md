# x402 / MPP — copy-pasteable recipes

> **Use the snippet in `references/x402.md`** — it's the canonical, tested-against-real-endpoints version with v1+v2 support and the probe-first flow. This file is just shell-runnable convenience wrappers + the MPP variant.

## Prerequisites

- A Crossmint EVM wallet on the **same chain the endpoint accepts** (`base-sepolia` for staging, `base` for production)
- The wallet funded with **USDC** on that chain (NOT USDXM — no x402 endpoint accepts USDXM). Staging: [faucet.circle.com](https://faucet.circle.com/) → paste address → pick Base Sepolia → request. See `references/funding-staging-wallets.md`.
- The agent is the wallet's signer (server-signer wallets satisfy this by definition)

---

## x402 — runnable end-to-end with probe + confirm + pay

This is the working snippet from `references/x402.md`, packaged as a one-shot Bash that the agent can run inline. **Always probe first** — do not skip Step 1.

### Step 1 — probe (read-only, safe)
```bash
curl -si "$TARGET_URL" | head -50
```

Read off `x402Version`, `accepts[0].network`, `accepts[0].maxAmountRequired` (raw USDC, divide by 1e6 for dollars), `accepts[0].payTo`.

### Step 2 — confirm with user
> "Endpoint requires up to **$X.XX USDC** on **<network>** (x402 v<N>). Pay? (y/N)"

Wait for "yes" before running step 3.

### Step 3 — sign + retry
```bash
mkdir -p /tmp/crossmint-x402 && cd /tmp/crossmint-x402
[ -f package.json ] || npm init -y >/dev/null 2>&1
npm i @crossmint/wallets-sdk @x402/core @x402/evm viem >/dev/null 2>&1

cat > pay.mjs <<'EOF'
import { createCrossmint, CrossmintWallets, EVMWallet } from "@crossmint/wallets-sdk";
import { x402Client } from "@x402/core/client";
import { encodePaymentSignatureHeader } from "@x402/core/http";
import { ExactEvmSchemeV1 } from "@x402/evm/exact/v1/client";
import { ExactEvmScheme }   from "@x402/evm/exact/client";

const TARGET = process.env.TARGET_URL;
const CHAIN  = process.env.CHAIN || "base-sepolia";          // match endpoint network

const crossmint = createCrossmint({ apiKey: process.env.CROSSMINT_API_KEY });
const wallets = CrossmintWallets.from(crossmint);
const wallet = await wallets.getWallet(
  process.env.WALLET_LOCATOR || `evm:alias:${process.env.WALLET_ALIAS || "claude-agent-wallet"}`,
  { chain: CHAIN }
);
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });
const evmWallet = EVMWallet.from(wallet);

const x402Signer = {
  address: evmWallet.address,
  async signTypedData(typedData) {
    const { signature } = await evmWallet.signTypedData({ ...typedData, chain: CHAIN });
    return signature;
  },
};

const client = new x402Client();
client.register("eip155:*", new ExactEvmScheme(x402Signer));
client.registerV1(CHAIN, new ExactEvmSchemeV1(x402Signer));

// PROBE
const probe = await fetch(TARGET, { method: "GET" });
if (probe.status !== 402) {
  console.log(JSON.stringify({ status: probe.status, body: await probe.text() }, null, 2));
  process.exit(0);
}
const paymentRequired = await probe.json();
console.error("version:", paymentRequired.x402Version,
              "max:",     paymentRequired.accepts[0].maxAmountRequired,
              "network:", paymentRequired.accepts[0].network);

// SIGN
const paymentPayload = await client.createPaymentPayload(paymentRequired);
const headerValue = encodePaymentSignatureHeader(paymentPayload);
const headerName  = paymentPayload.x402Version === 1 ? "X-PAYMENT" : "PAYMENT-SIGNATURE";

// RETRY (resign for each attempt — payloads expire)
const paid = await fetch(TARGET, { method: "GET", headers: { [headerName]: headerValue } });
const body = await paid.text();
const receiptB64 = paid.headers.get("x-payment-response");
const receipt = receiptB64 ? JSON.parse(Buffer.from(receiptB64, "base64").toString()) : null;

console.log(JSON.stringify({ status: paid.status, body, receipt }, null, 2));
EOF

( set -a; source "${HOME}/.config/crossmint/.env"; set +a; \
  TARGET_URL="https://api.example.com/protected" \
  CHAIN="base-sepolia" \
  WALLET_ALIAS="claude-agent-wallet" \
  node pay.mjs )
```

### Decoding the receipt
```bash
echo "$X_PAYMENT_RESPONSE_HEADER" | base64 -d | jq .
# { "success": true, "transaction": "0x...", "network": "base-sepolia", "payer": "0x..." }
```

---

## MPP — pay a Machine Payment Protocol endpoint

> Source: `references/mpp.md`. MPP and x402 differ in the negotiation protocol — do NOT copy the x402 snippet for MPP without reading the MPP doc first. MPP uses `mppx/client` instead of `@x402/core`.

### Install
```bash
npm i @crossmint/wallets-sdk mppx/client viem
```

### Same probe-first principle applies — read `references/mpp.md` for the actual call shape.

---

## Anti-patterns to refuse on sight

- **No probe.** "Just pay this URL" without `curl -si` first → reject. You'll waste a retry loop figuring out version + network + amount.
- **`wrapFetchWithPayment`.** Removed in `@x402/core ≥ 2.11.0`. If you see it in any code sample, replace with the manual flow above.
- **Hardcoded header name.** Always derive from `paymentPayload.x402Version` (`X-PAYMENT` for v1, `PAYMENT-SIGNATURE` for v2).
- **Reusing a payment payload across retries.** EIP-3009 has a `validBefore` (~15 min). Re-sign each attempt.
- **Skipping the chain check.** If wallet is `base-sepolia` and the endpoint says `accepts[0].network: "base"`, you'll burn a sign + get a facilitator-side reject. Cross-check before signing.
- **Funding with USDXM for x402.** USDXM is Crossmint's testnet token; no x402 endpoint takes it. Use base-sepolia USDC.
