# Wallet Action: List Transfers

> Source: `https://docs.crossmint.com/wallets/guides/list-transfers`. Cursor-paginated transfer history (in + out) across chains.

## Prerequisites
- API scope: `wallets.transaction.read`.

## SDK

```typescript
const transfers = await wallet.transfers({
  tokens: "usdc",            // optional, comma-separated symbols
  status: "successful",      // optional
  // chain omitted → uses wallet.chain
  // limit / cursor handled by SDK pagination iterator
});
```

## REST

```
GET /api/unstable/wallets/{walletLocator}/transfers
GET /api/unstable/wallets/me:walletLocator/transfers   # JWT auth variant
```

```bash
curl --request GET \
  --url 'https://staging.crossmint.com/api/unstable/wallets/WALLET_LOCATOR/transfers?chain=ethereum-sepolia&tokens=usdc&status=successful&limit=10' \
  --header 'X-API-KEY: YOUR_SERVER_API_KEY'
```

## Query parameters

| Param | Type | Notes |
|---|---|---|
| `chain` | string | e.g. `ethereum-sepolia`, `base`, `solana`, `stellar` |
| `tokens` | string | Optional, e.g. `usdc` |
| `status` | string | Optional, e.g. `successful` |
| `limit` | integer | Page size |
| `cursor` | string | Pagination cursor from previous response |

## Response

```json
{
  "data": [
    {
      "transferId": "...",
      "direction": "in" | "out",
      "amount": "...",
      "token": "usdc",
      "timestamp": "2026-01-15T10:30:00.000Z"
    }
  ],
  "nextCursor": "...",
  "previousCursor": "..."
}
```

Timestamps are ISO 8601. Loop until `nextCursor` is null:

```javascript
let cursor = null;
const all = [];
do {
  const params = new URLSearchParams({ chain, tokens, limit: "30" });
  if (cursor) params.set("cursor", cursor);
  const res = await fetch(`${baseUrl}?${params}`, {
    headers: { "X-API-KEY": "YOUR_SERVER_API_KEY" }
  });
  const result = await res.json();
  all.push(...result.data);
  cursor = result.nextCursor;
} while (cursor);
```

## Notes

- Endpoint is under `/api/unstable/` — breaking changes possible. Pin the version when shipping.
- Results cached ~10 minutes for EVM and Solana.
- Includes both `wallets.transfer.in` and `wallets.transfer.out`.
