# Using the Wallet

> Use the wallet to send stablecoins, swap, bridge, and call any contract from your agent.

## Introduction

Once a signer is authorized, your agent can drive the wallet like any EOA: **send stablecoins, swap, bridge, or call an arbitrary contract**. All operations go through the same `wallet` handle — the only thing that changes is which signer is active.

Policies attached to the server signer (spend caps, allowed contracts) are enforced on every transaction, so the agent can only sign what the user delegated.

## Prerequisites

* A user wallet with an authorized server signer. See [Authorize the Agent](/agents/payment-methods/stablecoin-wallets/authorize-agent) if you have not done this yet.
* The `walletAddress` of the user's wallet.
* A Crossmint **server-side** API key and the `CROSSMINT_SIGNER_SECRET` for the authorized signer.

## Activate the Server Signer

Before any server-side signing, activate the authorized server signer. Every subsequent call on that `wallet` handle is signed in-process with no user prompt.

```typescript theme={null}
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({
    apiKey: process.env.CROSSMINT_SERVER_SIDE_API_KEY,
});
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.getWallet(walletAddress, { chain: "base-sepolia" });

await wallet.useSigner({
    type: "server",
    secret: process.env.CROSSMINT_SIGNER_SECRET,
});
```

## Send Stablecoins

The canonical agent action: transfer stablecoins to a recipient. Wrap it in a server action so the secret stays on the backend.

```typescript theme={null}
"use server";

import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

export async function sendUsdxmFromServer({
    walletAddress,
    recipient,
    amount,
}: {
    walletAddress: string;
    recipient: string;
    amount: string;
}) {
    const crossmint = createCrossmint({
        apiKey: process.env.CROSSMINT_SERVER_SIDE_API_KEY,
    });
    const wallets = CrossmintWallets.from(crossmint);
    const wallet = await wallets.getWallet(walletAddress, { chain: "base-sepolia" });

    await wallet.useSigner({
        type: "server",
        secret: process.env.CROSSMINT_SIGNER_SECRET,
    });

    const tx = await wallet.send(recipient, "usdxm", amount);
    return { hash: tx.hash, explorerLink: tx.explorerLink };
}
```

`wallet.send(recipient, symbol, amount)` accepts any token symbol the chain supports (`usdc`, `usdt`, `usdxm` on staging, native gas tokens). The transaction is sponsored by default — the user does not need to hold ETH for gas.

See [Transfer Tokens](/wallets/guides/transfer-tokens) for the full symbol list and per-chain behavior.

## Read Balances

```typescript theme={null}
const balances = await wallet.balances(["usdxm", "eth"]);
const usdxm = balances.tokens.find((t) => t.symbol === "usdxm");
```

`balances()` returns native balance and token balances in one call. Pass an explicit array to include non-default symbols. For richer patterns (historical, multi-chain aggregation), see [Check Balances](/wallets/guides/check-balances).

## Fund a Staging Wallet

On supported staging chains, you can mint test stablecoins directly into the wallet — no faucet round-trip.

```typescript theme={null}
await wallet.stagingFund(5); // 5 USDXM
```

<Note>
  This is staging-only and exists to unblock local development. For production funding flows, see [Onramp & Add Funds](/agents/payment-methods/stablecoin-wallets/onramp-add-funds). For EVM-native testnet tokens, see [Get Staging Tokens](/wallets/guides/get-staging-tokens).
</Note>

## Call Any Contract

The wallet exposes a generic transaction path for anything that is not a first-class helper — swaps, bridges, DeFi, NFT mints, custom protocols. The exact call shape differs per chain; follow the reference for the chain you are targeting:

| Chain   | Reference                                                              |
| ------- | ---------------------------------------------------------------------- |
| EVM     | [Send Transaction (EVM)](/wallets/guides/send-transaction-evm)         |
| Solana  | [Send Transaction (Solana)](/wallets/guides/send-transaction-solana)   |
| Stellar | [Send Transaction (Stellar)](/wallets/guides/send-transaction-stellar) |

## Common Gotchas

<AccordionGroup>
  <Accordion title="Calling `useSigner` is a per-handle setting">
    Activating a signer applies only to the `wallet` handle you call it on. If you load a fresh wallet via `getWallet`, you must call `useSigner` again before signing.
  </Accordion>

  <Accordion title="Sponsored gas does not extend to all chains">
    Gas sponsorship is enabled by default on supported chains, but check the chain matrix in [Transfer Tokens](/wallets/guides/transfer-tokens) before assuming the user does not need a gas balance.
  </Accordion>
</AccordionGroup>

## Next Steps

<CardGroup cols={2}>
  <Card title="x402 Payment Flow" icon="bolt" href="/agents/payment-flows/x402">
    Pay HTTP-402-gated endpoints automatically using the authorized wallet.
  </Card>

  <Card title="Wallet Guides" icon="book" href="/wallets/guides/create-wallet">
    Full reference for signers, transactions, webhooks, and error handling.
  </Card>
</CardGroup>
