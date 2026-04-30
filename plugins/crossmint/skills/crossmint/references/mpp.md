# MPP

> Pay MPP endpoints with a Crossmint EVM wallet

This guide shows how to pay MPP (Machine Payment Protocol) endpoints using a Crossmint wallet. The example uses the `mppx/client` library to handle the payment flow automatically.

## Prerequisites

* A Crossmint EVM wallet with USDC. See the [Wallets quickstart](/agents/stablecoin-wallet-quickstart).
* The agent must be authorized as a signer on the wallet. See [Authorize the Agent](/agents/payment-methods/stablecoin-wallets/authorize-agent).

## Install dependencies

<CodeGroup>
  ```bash npm theme={null}
  npm i @crossmint/client-sdk-react-ui mppx/client viem
  ```

  ```bash yarn theme={null}
  yarn add @crossmint/client-sdk-react-ui mppx/client viem
  ```

  ```bash pnpm theme={null}
  pnpm add @crossmint/client-sdk-react-ui mppx/client viem
  ```

  ```bash bun theme={null}
  bun add @crossmint/client-sdk-react-ui mppx/client viem
  ```
</CodeGroup>

## Pay an MPP endpoint

```tsx mpp-payment.tsx theme={null}
import { EVMWallet, useWallet } from "@crossmint/client-sdk-react-ui";
import {
  createWalletClient,
  custom,
  http,
  MethodNotFoundRpcError,
  type EIP1193RequestFn,
} from "viem";
import { tempoDevnet } from "viem/chains";
import { Mppx, tempo } from "mppx/client";
import { CrossmintWallets, createCrossmint } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({
    apiKey: "<your-server-api-key>",
});

const crossmintWallets = CrossmintWallets.from(crossmint);

const wallet = await crossmintWallets.getWallet(
    "<wallet-address>",
    { chain: "base" }
);

// Use the agent signer
await wallet.useSigner({
    type: "server",
    secret: process.env.CROSSMINT_SIGNER_SECRET,
});

const evmWallet = EVMWallet.from(wallet);
const address = evmWallet.address as `0x${string}`;

const httpTransport = http();

const request: EIP1193RequestFn = async ({ method, params }) => {
  if (method === "wallet_sendCalls") {
    throw new MethodNotFoundRpcError(
      new Error("wallet_sendCalls not implemented; falling back"),
    );
  }
  if (method === "eth_sendTransaction") {
    const [tx] = params as Array<{
      to: `0x${string}`;
      data?: `0x${string}`;
      value?: `0x${string}`;
    }>;
    const sent = await evmWallet.sendTransaction({
      to: tx.to,
      data: tx.data ?? "0x",
      value: tx.value ? BigInt(tx.value) : undefined,
    });
    return sent.hash as `0x${string}`;
  }
  return httpTransport.request({ method, params } as any);
};

const walletClient = createWalletClient({
  account: address,
  chain: tempoDevnet,
  transport: custom({ request }),
});

const mppx = Mppx.create({
  polyfill: false,
  methods: [
    tempo({
      mode: "push",
      getClient: () => walletClient as any,
    }),
  ],
});

const response = await mppx.fetch("https://api.example.com/protected");

const responseText = await response.text();
console.log("MPP response:", response.status, responseText);
```

## How the code works

<Steps>
  <Step title="Create a wallet client from the Crossmint wallet">
    The `EVMWallet.from(wallet)` call wraps the Crossmint wallet into an EVM-compatible interface. A custom EIP-1193 request handler is created that delegates `eth_sendTransaction` calls to the Crossmint wallet, which sends transactions using the agent's delegated permissions.
  </Step>

  <Step title="Build a viem wallet client">
    A viem `walletClient` is created with the custom transport, targeting the Tempo devnet chain. This client bridges the Crossmint wallet to standard EVM tooling.
  </Step>

  <Step title="Initialize the MPPX client with Tempo">
    `Mppx.create` initializes the MPP client with the `tempo` payment method in push mode. The `getClient` callback provides the wallet client for signing and sending payment transactions.
  </Step>

  <Step title="Fetch the MPP endpoint">
    `mppx.fetch` works like a standard `fetch` call but automatically handles MPP payment negotiation. If the endpoint requires payment, the client pays via Tempo and retries the request.
  </Step>
</Steps>
