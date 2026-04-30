# Create Wallet (REST API)

> Source-of-truth fetched from `https://docs.crossmint.com/api-reference/wallets/create-wallet`. **For server-signer wallets, use the SDK instead** — see `references/server-signer.md`. The REST shape below is for external-wallet, passkey, email, or phone signers where you (or the user) manage the key directly.

## Endpoint

```
POST https://www.crossmint.com/api/2025-06-09/wallets        # production
POST https://staging.crossmint.com/api/2025-06-09/wallets    # staging
```

## Headers

| Header | Required | Notes |
|---|---|---|
| `X-API-KEY` | Yes | Server-side (`sk_*`) for autonomous flows; client-side (`ck_*`) when an end-user passkey/email is the signer |
| `Content-Type` | Yes | `application/json` |
| `x-idempotency-key` | No | Send a stable UUID to make retries safe — same key returns the same wallet instead of creating a duplicate |

## Request body — top-level

The body is a `oneOf` over wallet types. The shared shape:

```json
{
  "chainType": "evm" | "solana" | "aptos" | "sui" | "stellar",
  "type": "smart" | "mpc",
  "config": { /* chain-specific, see below */ },
  "owner": "<owner-locator-string>",        // optional for autonomous; required for user-bound
  "alias": "<human-readable-handle>"        // optional but recommended — addresses the wallet by name
}
```

### `owner` formats
- `email:user@example.com` — wallet bound to an email
- `userId:abc123` — wallet bound to your auth provider's user id
- `phoneNumber:+15551234567` — E.164
- `twitter:handle`
- `COMPANY` (literal, uppercase) — autonomous, no end user; the project owns the wallet

> For server-signer wallets, the SDK omits `owner` entirely and the wallet ends up `COMPANY`-owned.

### `alias`
A free-form string. Used to retrieve the wallet later via the locator `<chainType>:alias:<your-alias>` (e.g. `evm:alias:my-server-wallet`).

## EVM Smart Wallet

```json
{
  "chainType": "evm",
  "type": "smart",
  "config": {
    "adminSigner": {
      "type": "api-key" | "external-wallet" | "passkey" | "email" | "phone"
    },
    "delegatedSigners": [],
    "creationSeed": "<optional-string>"
  },
  "owner": "email:user@example.com",
  "alias": "my-usdc-wallet"
}
```

### `adminSigner` variants

| Type | Extra fields | When |
|---|---|---|
| `api-key` | none | Server-signer wallets created via the SDK (the SDK derives the address from your `CROSSMINT_SIGNER_SECRET`) |
| `external-wallet` | `address` (0x…) | The user (or you) manages the private key and signs locally |
| `passkey` | `id`, `name`, `publicKey: { x, y }` (decimal coords) | End-user passkey-backed wallet |
| `email` | `email` | End-user email-recovery wallet (default for `CrossmintWalletProvider`'s `createOnLogin`) |
| `phone` | `phone` (E.164) | End-user phone-recovery wallet |

## EVM MPC Wallet

```json
{
  "chainType": "evm",
  "type": "mpc",
  "config": {},
  "owner": "email:user@example.com"
}
```

## Solana

Same structure with `"chainType": "solana"`. Both `smart` and `mpc` types supported.

## Aptos / Sui

MPC only:

```json
{
  "chainType": "aptos" | "sui",
  "type": "mpc",
  "config": {},
  "owner": "<owner-locator>"
}
```

## Stellar

```json
{
  "chainType": "stellar",
  "type": "smart",
  "config": {
    "adminSigner": { /* same variants as EVM */ },
    "delegatedSigners": [],
    "plugins": ["<optional-plugin-name>"]
  },
  "owner": "<owner-locator>",
  "alias": "<optional>"
}
```

## Response (201 Created / 200 OK)

```json
{
  "chainType": "evm",
  "type": "smart",
  "address": "0x1234...",
  "config": {
    "adminSigner": {
      "type": "external-wallet",
      "address": "0x...",
      "locator": "external-wallet:0x..."
    },
    "delegatedSigners": []
  },
  "owner": "email:test@example.com",
  "createdAt": "2026-04-29T19:00:00.000Z",
  "alias": "my-usdc-wallet"
}
```

## Example — autonomous EVM smart wallet via curl (external-wallet signer)

```bash
curl -X POST https://staging.crossmint.com/api/2025-06-09/wallets \
  -H "X-API-KEY: ${CROSSMINT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "chainType": "evm",
    "type": "smart",
    "config": {
      "adminSigner": {
        "type": "external-wallet",
        "address": "0x1234567890123456789012345678901234567890"
      }
    },
    "owner": "COMPANY",
    "alias": "external-keyed-wallet"
  }'
```

## Error 400

Returned if a wallet with the same `creationSeed` and signer config already exists. Solve by:
- Reusing the existing wallet (same seed → same address — the API is idempotent on this combo), or
- Passing a fresh `creationSeed`.
