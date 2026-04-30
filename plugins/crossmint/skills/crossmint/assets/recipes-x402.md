# x402 / MPP — copy-pasteable recipes

> Lifted from `references/x402.md` and `references/mpp.md`. Adapt the URLs and merchant context; do not invent SDK fields.

## Prerequisites

Both flows assume:
- A Crossmint EVM wallet on Base with USDC (`references/stablecoin-wallets-quickstart.md`)
- The agent is authorized as a signer on the wallet (`references/authorize-agent.md`)

---

## 1. x402 — pay an `HTTP 402 Payment Required` endpoint

Source: `references/x402.md`.

### Install
```bash
npm i @crossmint/client-sdk-react-ui @crossmint/wallets-sdk @x402/core @x402/evm viem
```

### Pay
```tsx
import { EVMWallet } from "@crossmint/client-sdk-react-ui";
import { x402Client, x402HTTPClient, wrapFetchWithPayment } from "@x402/core/client";
import { ExactEvmScheme } from "@x402/evm/exact/client";
import type { Hex } from "viem";
import { CrossmintWallets, createCrossmint } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({ apiKey: "<your-server-api-key>" });
const crossmintWallets = CrossmintWallets.from(crossmint);

const wallet = await crossmintWallets.getWallet("<wallet-address>", { chain: "base" });

await wallet.useSigner({
  type: "server",
  secret: process.env.CROSSMINT_SIGNER_SECRET!,
});

const evmWallet = EVMWallet.from(wallet);

const x402Signer = {
  address: evmWallet.address as `0x${string}`,
  async signTypedData(typedData: any) {
    const { signature } = await evmWallet.signTypedData({
      ...typedData,
      chain: "base",
    });
    return signature as Hex;
  },
};

const client = new x402Client();
client.register("eip155:*", new ExactEvmScheme(x402Signer));

const fetchWithPayment = wrapFetchWithPayment(fetch, client);

// Now fetchWithPayment auto-handles 402:
// 1. First request returns 402 with payment terms
// 2. SDK signs a stablecoin payment
// 3. Retries with payment proof; you get the real response
const response = await fetchWithPayment("https://api.example.com/protected", {
  method: "GET",
});

if (response.ok) {
  const httpClient = new x402HTTPClient(client);
  const paymentReceipt = httpClient.getPaymentSettleResponse(
    (name) => response.headers.get(name)
  );
  console.log("Payment settled on-chain:", paymentReceipt);
}
```

### When to use which scheme
- `ExactEvmScheme` — exact-amount payments on any EIP-155 chain (Base, Ethereum, etc.). Register under `eip155:*`.
- For other chains / schemes, see the upstream `@x402/core` docs (not shipped here).

---

## 2. MPP — pay a Machine Payment Protocol endpoint

Source: `references/mpp.md`.

### Install
```bash
npm i @crossmint/client-sdk-react-ui mppx/client viem
```

### Pay
Read `references/mpp.md` for the full integration — the client wraps `fetch` similarly to the x402 example, but the negotiation protocol differs. Do not copy the x402 snippet for MPP without reading the MPP doc first.

---

## Common gotchas

- **Wrong chain.** The `useSigner` call and the `evmWallet.signTypedData({ chain: "base" })` call must agree. Mainnet is `"base"`, testnet is `"base-sepolia"`.
- **Missing USDC.** A 402 endpoint will reject the payment if the wallet balance is below the requested amount. Check via the wallets SDK before calling, or surface the on-chain error to the user.
- **Server vs client signer.** In the x402 example, `useSigner({ type: "server", secret: ... })` is used — the agent signs without user approval because the user already authorized the server signer at setup time. If you instead use `{ type: "email" }`, every payment triggers an email code (not what you want for autonomous agents).
