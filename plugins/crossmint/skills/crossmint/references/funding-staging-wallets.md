# Funding Staging Wallets

> Every agent demo that pays for things needs a funded wallet. There are two paths on staging — pick by what the wallet will *do*, not by what's most convenient.

## TL;DR — pick by use case

| If the wallet will… | Fund with | How |
|---|---|---|
| Pay an **x402** endpoint | **base-sepolia USDC** | [Circle faucet](https://faucet.circle.com/) — paste address, pick "Base Sepolia", request. No auth, no login, no captcha-loop. |
| Test **`wallet.send` / `wallet.transfer`** between Crossmint wallets only | **USDXM** | `await wallet.stagingFund(10)` — one SDK call, no external steps |
| Test **`wallet.send("usdc", ...)`** code paths that mirror production | **base-sepolia USDC** | Circle faucet (above) |
| Pay an **MPP** endpoint | Same as x402 — check the endpoint's payment scheme; almost always USDC | Circle faucet |
| **Worldstore order on staging** | **base-sepolia USDC** (the order is denominated in USDC) | Circle faucet |

> **No live x402 endpoint accepts USDXM.** USDXM is a Crossmint-internal testnet token — useful for self-contained Crossmint demos, useless for real protocol testing. Default to USDC for any flow that touches an external endpoint.

## How the agent should fund a wallet for x402 / Worldstore / USDC tests

When the user asks "fund my wallet" or wallet-balance shows zero USDC and the next intended action is x402 / commerce / send-USDC, run this:

1. Compute the wallet address (`wallet.address` from `getWallet` or the create-wallet response).
2. Tell the user, **verbatim**:

   > Go to [faucet.circle.com](https://faucet.circle.com/) — paste this address, pick **Base Sepolia**, request USDC. No login required.
   >
   > Address: `0xYOUR_WALLET_ADDRESS`
   >
   > Tell me when you've done it; I'll confirm the balance landed.

3. Wait for the user to confirm.
4. Re-check the balance:
   ```typescript
   const { tokens } = await wallet.balances(["usdc"]);
   ```
5. Once `tokens` shows USDC > 0, proceed with the original task.

## How the agent should fund a wallet for self-contained demos

When the user just wants to see USDXM move between Crossmint wallets (no external endpoint), use the SDK faucet directly — no human needed:

```typescript
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });
await wallet.stagingFund(10);                        // mints 10 USDXM to the wallet
const { tokens } = await wallet.balances(["usdxm"]);
```

Source: `references/wallet-quickstart-react.md` and `references/wallet-actions/wallet-methods.md`.

## Production funding

There's **no `stagingFund`** in production and **no USDXM**. The user's own funds enter the wallet via:

- **Card-to-USDC onramp** — see `references/onramp.md`
- **Direct send** from another wallet (CEX withdrawal, MetaMask, etc.)
- **Worldstore order received as proceeds** (rare)

When you switch the user from staging to production, swap every `"usdxm"` symbol in their code to `"usdc"`.

## Common gotchas

- **Don't fund with USDXM and then try x402.** The 402 negotiation will fail because no x402 endpoint accepts USDXM. The error usually mentions "no payment scheme accepted" or similar.
- **Don't assume `wallet.stagingFund` works on production.** It only exists on staging environments. Calling it in production throws.
- **The Circle faucet rate-limits per address.** If the user hits the limit, suggest a fresh wallet alias rather than retrying.
- **Smart wallets pay gas via Crossmint's paymaster.** No need to fund native ETH on Base Sepolia for smart wallets — only the token you intend to spend.
