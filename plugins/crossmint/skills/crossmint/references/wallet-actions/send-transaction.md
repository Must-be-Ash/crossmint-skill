# Wallet Action: Send Transaction (arbitrary contract call)

> Source: `https://docs.crossmint.com/api-reference/wallets/create-transaction`. Use this for arbitrary contract calls, not plain token transfers — for sending USDC/ETH/etc. use `transfer-tokens.md`.

## Prerequisites
- API scope: `wallets:transactions.create`.

## SDK — Node.js (EVM smart wallet)

The SDK abstracts the calls list. For typical contract calls, prefer the higher-level helpers (`wallet.send` for transfers). For raw `calls`:

```typescript
import { CrossmintWallets, createCrossmint, EVMWallet } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: "<sk_staging_…>" });
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.getWallet("evm:alias:my-wallet", { chain: "base-sepolia" });
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });

// EVMWallet exposes the raw transaction surface.
const evm = EVMWallet.from(wallet);

// One contract call (function on a deployed contract):
const tx = await evm.sendTransaction({
  calls: [{
    to:    "0xCONTRACT_ADDRESS",
    data:  "0xENCODED_CALLDATA",   // viem.encodeFunctionData(...) etc.
    value: 0n,                      // bigint, in native-token wei
  }],
});

console.log(tx.hash, tx.explorerLink);
```

For EIP-712 payment transactions (e.g. an x402 settlement), see `references/x402.md` — it uses `signTypedData` instead of `sendTransaction`.

## REST — `POST /api/2025-06-09/wallets/{walletLocator}/transactions`

### EVM smart wallet — function call

```bash
curl --request POST \
  --url 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm:smart/transactions' \
  --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
  --header 'Content-Type: application/json' \
  --header 'x-idempotency-key: optional-stable-uuid' \
  --data '{
    "params": {
      "calls": [
        {
          "address":      "0x1234567890123456789012345678901234567890",
          "functionName": "transfer",
          "abi":          [/* the function ABI */],
          "args":         ["0xRECIPIENT", "1000000"],
          "value":        "0"
        }
      ],
      "chain":  "base-sepolia",
      "signer": "api-key:<your-server-signer-locator>"
    }
  }'
```

### EVM — pre-built serialized transaction (e.g. from a Worldstore order)

```json
{
  "params": {
    "calls": [{ "transaction": "0xSERIALIZED_TX_HEX" }],
    "chain": "base-sepolia"
  }
}
```

This shape is what `references/inventory.md` uses to submit the Crossmint Worldstore payment.

### Solana smart wallet

```json
{
  "params": {
    "transaction": "BASE58_SERIALIZED_TX",
    "signer": "external-wallet:<base58-pubkey>"
  }
}
```

### Stellar
Contract-call shape — see the live API ref for full schema.

## `signer` formats

- `api-key:<id>` — your project's API-key/server signer
- `email:user@example.com` — user's email-recovery signer
- `passkey:<credential-id>` — passkey-recovery signer
- `external-wallet:<address>` — user-managed key

## Response

```json
{
  "id": "tx_…",
  "chainType": "evm",
  "walletType": "smart",
  "status": "awaiting-approval | pending | success | failed",
  "params": { "calls": [...], "chain": "base-sepolia", "signer": {...} },
  "onChain": { "userOperationHash": "0x…", "txId": null },
  "approvals": {
    "pending":  [{ "signer": {...}, "message": "0x…" }],
    "submitted": [{ "signature": "0x…", "submittedAt": "...", "signer": {...} }],
    "required": 1
  },
  "createdAt": "ISO8601",
  "completedAt": "ISO8601",
  "error": { "reason": "...", "message": "..." }
}
```

## Status values

- `awaiting-approval` — pending required signatures (REST flow only; SDK collapses)
- `pending` — submitted, awaiting chain finality
- `success` — confirmed
- `failed` — execution failed (`error.reason` and `error.message` give context)

Poll `GET /api/2025-06-09/wallets/{walletLocator}/transactions/{id}` or use webhooks.

## Common gotchas

- **Smart wallets pay gas via paymaster.** Don't manually set gas params — the userOperation is sponsored.
- **`value` is a string for REST, bigint for SDK.** Wei for EVM, lamports for Solana.
- **For Worldstore orders**, use the `serializedTransaction` returned by the order API verbatim — see `references/inventory.md`.
- **Approval flow** (REST only): if `status === "awaiting-approval"`, you must sign each `approvals.pending[].message` and POST them back to `/transactions/{id}/approvals`. The SDK does this automatically.
