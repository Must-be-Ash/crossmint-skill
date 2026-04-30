# Server Agent Wallets

> Backend-only wallets for autonomous agents with no end user. The backend is the root signer; there is no user OTP, no email recovery, no human in the loop.

> **Authoritative source for the SDK shape: `references/server-signer.md`.** That file ships the full `createWallet`, `getWallet`, and `useSigner` patterns. This page is the conceptual + ops view; the canonical code lives there.

## When to use this

- Autonomous market makers, treasury bots, scheduled task runners
- Agents you (the developer) operate end-to-end — no end-user account needed
- Anywhere the human-in-the-loop user-authorized flow would be friction

The trade-off vs the user-authorized flow: there is no recovery signer to fall back to if your backend is compromised. The signer secret IS the wallet. Treat it like a production database password.

## Prerequisites

- A Crossmint **server-side** API key from the [Crossmint Console](https://staging.crossmint.com/console/projects/apiKeys) (use staging for testing). Server keys have prefix `sk_staging_…` or `sk_production_…`.
- A `CROSSMINT_SIGNER_SECRET` (`xmsk1_<64-hex>` or bare 64 hex). Generate with `openssl rand -hex 32` and prefix with `xmsk1_`. Store as an env var, KMS, or hardware-backed vault.

> If the user ran `scripts/setup.sh` from this skill, both are already in `~/.config/crossmint/.env`.

## Creating the wallet

> **The SDK shape is `recovery + alias`, NOT `signer + owner`.** This is the most common mistake. See `references/server-signer.md` for the full reasoning.

```typescript
import { CrossmintWallets, createCrossmint } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({
  apiKey: process.env.CROSSMINT_API_KEY,         // sk_staging_... or sk_production_...
});
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.createWallet({
  chain: "base-sepolia",                          // staging; use "base" in production
  recovery: {
    type: "server",
    secret: process.env.CROSSMINT_SIGNER_SECRET,
  },
  alias: "my-server-wallet",                      // your handle for getWallet later
});

console.log(wallet.address);                      // 0x...
```

Server-signer wallets are **company-owned** (the API records `owner: "COMPANY"`). You do not pass `owner:` — the SDK omits it.

## Retrieving the wallet later

```typescript
const wallet = await wallets.getWallet(
  "evm:alias:my-server-wallet",                   // Solana: "solana:alias:..."
  { chain: "base-sepolia" }
);

await wallet.useSigner({
  type: "server",
  secret: process.env.CROSSMINT_SIGNER_SECRET,
});
// wallet.signTypedData(...), wallet.send(...) etc. now work
```

## Using the wallet

Once `useSigner` is active:

- **Send stablecoins** — see `references/using-the-wallet.md`
- **Pay an x402 endpoint** — see `references/x402.md`
- **Pay an MPP endpoint** — see `references/mpp.md`
- **Sign arbitrary EIP-712** — `wallet.signTypedData({ ... })`
- **Submit a Worldstore order** — see `references/inventory.md` (use `payerAddress: wallet.address`)

## Common gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `recovery is required` | Passed `signer:` | Use `recovery: { type: "server", secret }` |
| `owner: invalid format` | Passed `owner: "agent:foo"` | Don't pass `owner` for server wallets — use `alias` |
| 403 from createWallet | Using `ck_*` (client) key | Server-signer wallets need `sk_*` |
| Signing fails after `getWallet` | Forgot `wallet.useSigner(...)` | Call `useSigner({ type: "server", secret })` after `getWallet` |
| Different address per env | Project ID + env are mixed into HKDF | Expected — staging and production derive different keys from the same secret |

## Limitations

- **REST API alone cannot create a server-signer wallet** — the secret never leaves your server, so the API has no way to derive the address. Use the SDK. (For pure-REST flows, use an `external-wallet` admin signer instead — see `references/api/create-wallet.md`.)
- **No recovery if the secret is lost** — there is no backup. Rotate quarterly; back up to a KMS.

## What is next

- `references/server-signer.md` — full SDK reference (key derivation, locators, security)
- `references/using-the-wallet.md` — sends, swaps, contract calls
- `references/x402.md` — pay 402-protected endpoints from this wallet
