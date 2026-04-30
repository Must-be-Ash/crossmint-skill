# Create Transaction (REST API)

> Source: `https://docs.crossmint.com/api-reference/wallets/create-transaction`. For high-level transfers prefer `wallet-actions/transfer-tokens.md`. For arbitrary contract calls, use this.

## Endpoint

```
POST https://www.crossmint.com/api/2025-06-09/wallets/{walletLocator}/transactions      # production
POST https://staging.crossmint.com/api/2025-06-09/wallets/{walletLocator}/transactions  # staging
```

## Headers

| Header | Required | Notes |
|---|---|---|
| `X-API-KEY` | Yes | Server-side key |
| `Content-Type` | Yes | `application/json` |
| `x-idempotency-key` | No | Stable UUID; same key returns the same transaction |

## Request body — EVM smart wallet (function call)

```json
{
  "params": {
    "calls": [
      {
        "address":      "0x...",
        "functionName": "transfer",
        "abi":          [/* function ABI */],
        "args":         ["0xRECIPIENT", "1000000"],
        "value":        "0"
      }
    ],
    "chain":  "base-sepolia",
    "signer": "api-key:<your-server-signer-locator>"
  }
}
```

## Request body — EVM smart wallet (pre-serialized tx)

```json
{
  "params": {
    "calls": [{ "transaction": "0xSERIALIZED_TX_HEX" }],
    "chain": "base-sepolia"
  }
}
```

This shape is used by `references/inventory.md` (Worldstore orders return a `serializedTransaction` you submit verbatim).

## Request body — EVM MPC wallet

Single call, no batched array. See live ref for the exact shape.

## Request body — Solana smart wallet

```json
{
  "params": {
    "transaction": "BASE58_SERIALIZED_TX",
    "signer": "external-wallet:<base58-pubkey>"
  }
}
```

## Request body — Stellar

Contract-call shape; see live ref for the full schema.

## `signer` field (string locator)

- `api-key:<id>` — server-signer
- `email:user@example.com` — email-recovery user
- `passkey:<credential-id>` — passkey-recovery user
- `external-wallet:<address>` — user-managed key

## Response (201 Created)

```json
{
  "id": "tx_...",
  "chainType": "evm",
  "walletType": "smart",
  "status": "awaiting-approval",
  "params": { "calls": [...], "chain": "base-sepolia", "signer": {...} },
  "onChain": { "userOperationHash": "0x...", "txId": null },
  "approvals": {
    "pending":   [{ "signer": {...}, "message": "0x..." }],
    "submitted": [{ "signature": "0x...", "submittedAt": "...", "signer": {...} }],
    "required":  1
  },
  "createdAt":  "2026-04-29T10:00:00.000Z",
  "completedAt": null,
  "error":      { "reason": "...", "message": "..." }
}
```

## Status values

| Status | Meaning |
|---|---|
| `awaiting-approval` | Created, waiting for required signers |
| `pending` | Submitted to chain, awaiting finality |
| `success` | Confirmed onchain |
| `failed` | Execution failed (`error.reason` populated) |

## Approval flow (when `status === "awaiting-approval"`)

For each `approvals.pending[].message`, sign it with the named signer, then:

```
POST /api/2025-06-09/wallets/{walletLocator}/transactions/{id}/approvals
{
  "approvals": [
    { "signer": "...", "signature": "0x..." }
  ]
}
```

The SDK collapses all of this into a single call. Use REST manually only if you can't use the SDK.

## Polling

```
GET /api/2025-06-09/wallets/{walletLocator}/transactions/{id}
```

Or set up [webhooks](https://docs.crossmint.com/wallets/guides/webhooks) for push updates.
