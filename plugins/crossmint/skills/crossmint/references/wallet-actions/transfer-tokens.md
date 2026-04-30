# Wallet Action: Transfer Tokens

> Source: `https://docs.crossmint.com/wallets/guides/transfer-tokens` and the REST quickstart. Smart wallets cover gas via Crossmint's paymaster.

## Prerequisites
- A wallet with a non-zero balance of the token you want to send.
- For server-signer wallets, the SDK and `CROSSMINT_SIGNER_SECRET` set; or use the REST flow with manual signature approval.
- API scope: `wallets:transactions.create`.

## SDK — Node.js / React

```typescript
const tx = await wallet.send(
  recipientAddress,    // string — destination address or locator
  tokenIdentifier,     // string — symbol ("usdc", "usdxm", "eth") or contract address
  amount               // string — decimal amount in human units (e.g. "0.001", "100")
);

console.log(tx.hash);          // transaction hash
console.log(tx.explorerLink);  // chain explorer URL
```

The SDK handles the chain context from the wallet's bound `chain`. Returns `{ hash, explorerLink }`.

## REST — token transfer

**URL pattern:**
```
POST https://{host}/api/2025-06-09/wallets/{walletLocator}/tokens/{tokenLocator}/transfers
```

- `host`: `staging.crossmint.com` or `www.crossmint.com`
- `walletLocator`: address (`0x…`), or `email:user@example.com:evm:smart`, or `evm:alias:<alias>`
- `tokenLocator`: `<chain>:<symbol>` (e.g. `base-sepolia:usdc`) OR `<chain>:<contractAddress>` (e.g. `base-sepolia:0x123…`)

```bash
curl --request POST \
  --url 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/tokens/base-sepolia:usdc/transfers' \
  --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "recipient": "0xRECIPIENT_ADDRESS",
    "amount": "0.50"
  }'
```

For external-wallet signers add `signer`:
```json
{
  "recipient": "0xRECIPIENT_ADDRESS",
  "amount": "0.50",
  "signer": "external-wallet:0xYOUR_EXTERNAL_WALLET_ADDRESS"
}
```

## Recipient formats

- Address: `0x…` (EVM) or base58 (Solana)
- Email: `email:user@example.com`
- User id: `userId:abc123`

## Common token locators

**EVM staging (testnet):** `base-sepolia:eth`, `base-sepolia:usdc`, `base-sepolia:usdxm`, `ethereum-sepolia:usdc`

**EVM production:** `base:usdc`, `polygon:usdc`, `ethereum:usdt`

**Solana:** `solana:sol`, `solana:usdc`

For arbitrary ERC-20s use the contract address: `base:0xA0b86991C6218b36C1D19D4A2E9Eb0CE3606eB48`

## Response

```json
{
  "id": "cm47h2m8e0003vn0zf8yz1234",
  "chainType": "evm",
  "walletType": "smart",
  "status": "pending",
  "params": {
    "calls": [],
    "chain": "base-sepolia",
    "signer": { "type": "evm-keypair", "address": "0x..." }
  },
  "onChain": { "userOperationHash": "0x...", "txId": null },
  "sendParams": { "token": "base-sepolia:usdc", "recipient": "0x...", "amount": "0.50" },
  "createdAt": "2026-04-29T10:35:00.000Z"
}
```

## Status values

- `awaiting-approval` — created, waiting for a signer
- `pending` — submitted on-chain, awaiting finality
- `success` — confirmed
- `failed` — execution failed

Poll the transaction by id, or set up webhooks (`/wallets/guides/webhooks`).

## Common gotchas

- **Amount is in human decimal units, not wei.** `"0.001"` = 0.001 ETH.
- **Token symbol is lowercase.** `"usdc"`, not `"USDC"`.
- **Smart wallets pay gas via paymaster.** No need to fund native gas tokens for smart wallets.
- **MPC wallets need their own gas.** Fund the wallet with the native chain token.
- **Server signer + REST:** the `wallets/.../transfers` endpoint returns the transaction in `awaiting-approval`. You must derive an approval signature and submit it via the approvals endpoint. Use the SDK to skip this entirely.
- **Transfers are irreversible** once confirmed.
