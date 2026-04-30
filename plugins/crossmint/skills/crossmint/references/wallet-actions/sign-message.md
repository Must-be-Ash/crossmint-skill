# Wallet Action: Sign Message (EVM)

> Source: `https://docs.crossmint.com/wallets/guides/sign-message-evm`. Covers EIP-191 plain messages and EIP-712 typed data.

## Prerequisites
- Existing wallet instance.
- API scope: `wallets:signatures.create`.
- For operational signers: **the wallet must have executed at least one transaction before signatures will work.** First-tx-then-sign.

## SDK — Node.js

### EIP-191 plain message
```typescript
import { CrossmintWallets, createCrossmint, EVMWallet } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: "<sk_staging_…>" });
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.getWallet(
  "email:user@example.com:evm",
  { chain: "base-sepolia" }
);
await wallet.useSigner({ type: "email", email: "user@example.com" });
// Or for server-signer wallets:
// await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });

const evmWallet = EVMWallet.from(wallet);
const { signature } = await evmWallet.signMessage({ message: "Hello, world!" });
```

### EIP-712 typed data
```typescript
const typedData = {
  types: {
    EIP712Domain: [{ name: "name", type: "string" }],
    Mail: [
      { name: "from", type: "Person" },
      { name: "to",   type: "Person" },
      { name: "contents", type: "string" }
    ],
    Person: [{ name: "name", type: "string" }]
  },
  primaryType: "Mail",
  domain: { name: "example.com", version: "1" },
  message: {
    from: { name: "John Doe" },
    to:   { name: "Jane Doe" },
    contents: "Hello, world!"
  }
};

const { signature } = await evmWallet.signTypedData(typedData);
```

For x402-style payments, use `signTypedData` with the chain field set explicitly:
```typescript
await wallet.signTypedData({ ...typedData, chain: "base" });
```
(See `references/x402.md`.)

## SDK — React

```tsx
import { useWallet, EVMWallet } from "@crossmint/client-sdk-react-ui";

const { wallet } = useWallet();
const evmWallet = EVMWallet.from(wallet);
const { signature } = await evmWallet.signMessage({ message: "Hello, world!" });
```

`signTypedData(typedData)` is identical in shape.

## REST — three-step flow

The SDK collapses these into one call. With REST you do them by hand.

### Step 1 — Create the signature request

```bash
# EIP-191 plain message
curl --request POST \
  --url https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures \
  --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "type": "message",
    "params": {
      "message": "Hello, world!",
      "signer": "email:user@example.com",
      "chain": "base-sepolia"
    }
  }'
```

```bash
# EIP-712 typed data — body skeleton
{
  "type": "typed-data",
  "params": {
    "typedData": { /* full EIP-712 object: types, primaryType, domain, message */ },
    "signer": "email:user@example.com",
    "chain": "base-sepolia"
  }
}
```

Response includes a `signature.id` and `signature.approvals[]` (the messages each signer must sign).

### Step 2 — Sign the approval (skip if `api-key` recovery)

For `email` / `phone` recovery, the user gets an OTP and signs in their UI. For `external-wallet` recovery, sign the exact hex message returned in `approvals[].message` with the user's wallet.

For `api-key` recovery (server-signer wallet), this step is automatic — skip ahead.

### Step 3 — Submit the approval

```bash
curl --request POST \
  --url https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures/<SIGNATURE_ID>/approvals \
  --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "approvals": [{
      "signer": "email:user@example.com",
      "signature": "0xRESULT_OF_STEP_2"
    }]
  }'
```

Once `approvals.required` are met, the signature object's status flips to `success` and the final signature is on the response.

## Difference between EIP-191 and EIP-712

| | EIP-191 | EIP-712 |
|---|---|---|
| SDK method | `signMessage({ message })` | `signTypedData(typedData)` |
| REST `type` | `"message"` | `"typed-data"` |
| Use for | Sign-in tokens, simple proofs | x402 payments, Permit2, contract-bound auth |

## Common gotchas

- **`useSigner` first.** `wallet.signMessage(...)` will throw if you haven't activated a signer.
- **Operational signers can't sign on a brand-new wallet.** Send any tx first to "warm up" the wallet.
- **Chain-bound signatures** (EIP-712 with `domain.chainId`): make sure your wallet's chain matches `domain.chainId`.
