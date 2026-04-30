# Wallet Action: Check Balances

> Source: `https://docs.crossmint.com/wallets/guides/check-balances` and the REST quickstart.

## Prerequisites
- API scopes: `wallets.read`, `wallets:balance.read`.

## SDK

```typescript
const { nativeToken, usdc, tokens } = await wallet.balances(["usdc", "usdxm"]);

for (const t of tokens) {
  console.log(`${t.symbol}: ${t.amount}`);
}
```

The SDK returns `nativeToken` (the chain's native asset, e.g. ETH/SOL), a top-level `usdc` shortcut if requested, and a `tokens[]` array for everything you asked for.

## REST

```
GET /api/2025-06-09/wallets/{walletLocator}/balances?tokens={comma-separated}&chains={optional-chain-filter}
```

```bash
curl --request GET \
  --url 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/balances?tokens=usdc,eth&chains=base-sepolia' \
  --header 'X-API-KEY: YOUR_SERVER_API_KEY'
```

## Query parameters

| Param | Type | Notes |
|---|---|---|
| `tokens` | required | Comma-separated symbols or addresses (`usdc,eth,0xA0b8…`) |
| `chains` | optional | Filter for multi-chain wallets (e.g. `base-sepolia`, `base,polygon`) |

## Response

```json
{
  "nativeToken": {
    "symbol": "ETH",
    "decimals": 18,
    "balance": "1500000000000000000",
    "balanceUSD": "4500.00"
  },
  "tokens": [
    {
      "symbol": "USDC",
      "decimals": 6,
      "balance": "1000000000",
      "balanceUSD": "1000.00",
      "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    }
  ]
}
```

> **Balances are strings in the token's smallest unit.** Wei for ETH (18 decimals), `usdc` smallest unit is 1e-6, etc. Divide by 10^decimals to get human units. The SDK exposes `t.amount` already converted; the REST `balance` field is raw.

## Common gotchas

- **Always pass `tokens=...`** — the endpoint requires at least one token.
- **`balanceUSD` may be absent** for thin-liquidity / unsupported assets.
- **Multi-chain wallets:** without `chains=`, balances are aggregated across all chains the wallet is bound to.
