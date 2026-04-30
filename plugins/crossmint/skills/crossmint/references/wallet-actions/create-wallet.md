# Wallet Action: Create Wallet

> Source: `https://docs.crossmint.com/wallets/guides/create-wallet` and the V1 quickstarts (`wallet-quickstart-node.md`, `wallet-quickstart-react.md`, `wallet-quickstart-rest.md`).

## Prerequisites
- Server-side API key (`sk_*`) with the `wallets.create` scope.
- For server-signer wallets: a 32-byte secret stored as `CROSSMINT_SIGNER_SECRET`. See `references/server-signer.md`.

## Supported chains

**EVM (require explicit `chain` parameter):**
- `ethereum-sepolia`, `polygon-amoy`, `base-sepolia`, `arbitrum-sepolia`, `optimism-sepolia` (staging)
- `ethereum`, `polygon`, `base`, `arbitrum`, `optimism` (production)

**Solana:** `solana` (devnet on staging; mainnet on production). No `chain` parameter — `chainType: "solana"` alone is enough.

## SDK — Node.js (server-signer wallet)

```typescript
import { CrossmintWallets, createCrossmint } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: "<sk_staging_…>" });
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.createWallet({
  chain: "base-sepolia",
  recovery: { type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET },
  // optional:
  // signers: [{ type: "server", secret: process.env.WALLET_SIGNER_SECRET }],
  // alias: "my-server-wallet",
});

console.log(wallet.address);
```

> The SDK's `recovery` maps to REST's `config.adminSigner` (the recovery role). The optional SDK `signers: []` maps to REST's `config.delegatedSigners` (operational signers). **The `signer` field used in older code samples does not exist on `createWallet` in V1.**

## SDK — React (created automatically on login)

```tsx
<CrossmintWalletProvider
  createOnLogin={{
    chain: "base-sepolia",
    recovery: { type: "email" },
  }}
>
  {children}
</CrossmintWalletProvider>
```

Then `const { wallet, status } = useWallet();`. Status values include `"in-progress"`, `"loaded"`, `"not-loaded"`. `wallet.address` and `wallet.chain` are available when `status === "loaded"`.

To create explicitly (instead of via `createOnLogin`):
```tsx
const { createWallet } = useWallet();
const wallet = await createWallet({
  chain: "base-sepolia",
  recovery: { type: "email", email: "user@example.com" },
});
```

## REST — server-signer EVM smart wallet

```bash
curl --request POST \
  --url https://staging.crossmint.com/api/2025-06-09/wallets \
  --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
  --header 'Content-Type: application/json' \
  --header 'x-idempotency-key: optional-stable-uuid' \
  --data '{
    "chainType": "evm",
    "chain": "base-sepolia",
    "config": {
      "adminSigner": {
        "type": "server",
        "address": "YOUR_SERVER_SIGNER_ADDRESS"
      }
    },
    "owner": "email:user@example.com"
  }'
```

> `adminSigner.address` for `type: "server"` is the address you pre-derive from your secret (HKDF-SHA256). The REST API never receives the secret. If you don't want to derive it yourself, use the SDK.

### REST — external-wallet admin signer (no Crossmint-managed key)
```json
{
  "chainType": "evm",
  "chain": "base-sepolia",
  "config": {
    "adminSigner": { "type": "external-wallet", "address": "0xYOUR_ADDRESS" }
  },
  "owner": "email:user@example.com"
}
```

### REST — email recovery (user-bound wallet, OTP approval)
```json
{
  "chainType": "evm",
  "chain": "base-sepolia",
  "config": {
    "adminSigner": { "type": "email", "email": "user@example.com" }
  },
  "owner": "email:user@example.com"
}
```

### REST — MPC (custodial; contact sales for access)
```json
{
  "chainType": "evm",
  "type": "mpc",
  "owner": "email:user@example.com"
}
```
MPC wallets omit `config.adminSigner` entirely.

## `owner` formats

- `email:user@example.com`
- `userId:abc123`
- `phoneNumber:+15551234567` (E.164)
- `twitter:handle` or `x:@handle`
- `COMPANY` (literal, uppercase) — autonomous; the project owns the wallet

## `alias`

Optional human-readable handle. Once set, retrieve the wallet later with the locator `<chainType>:alias:<your-alias>` (e.g. `evm:alias:my-server-wallet`).

## Response (201 Created)

```json
{
  "chainType": "evm",
  "type": "smart",
  "address": "0xABC...",
  "owner": "email:user@example.com",
  "config": {
    "adminSigner": {
      "type": "server",
      "address": "0xSIGNER_ADDR",
      "locator": "server:0xSIGNER_ADDR"
    }
  },
  "createdAt": "2026-04-29T10:30:00.000Z"
}
```

**Persist `address`** — every later call (balance, transfer, sign) keys off it (or the alias / locator).

## Idempotency

Send `x-idempotency-key: <uuid>` to make retries safe. Same key returns the same wallet without duplicating.

## Get-or-create pattern (SDK)

```typescript
import { WalletNotAvailableError } from "@crossmint/wallets-sdk";

let wallet;
try {
  wallet = await wallets.getWallet("evm:alias:my-wallet", { chain: "base-sepolia" });
} catch (e) {
  if (e instanceof WalletNotAvailableError) {
    wallet = await wallets.createWallet({
      chain: "base-sepolia",
      recovery: { type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET },
      alias: "my-wallet",
    });
  } else throw e;
}
```

## Common gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `recovery is required` | Passed `signer:` to `createWallet` | Use `recovery: { type: "server", secret }` |
| `owner: invalid format` | Used `agent:foo` | Use one of the formats above; for autonomous use `COMPANY` |
| `chain is required` | EVM wallet without `chain` | EVM needs an explicit chain (e.g. `"base-sepolia"`); Solana does not |
| Different addresses across staging vs production | Project ID + env are mixed into HKDF | Expected — derive a fresh address per environment |
