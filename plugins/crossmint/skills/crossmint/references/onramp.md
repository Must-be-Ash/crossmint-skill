# Onramp & Add Funds

> Let users fund their wallet with a credit card so the agent can spend from it.

## Introduction

Once a user wallet is created and the agent is authorized, the next step is to fund the wallet so the agent has stablecoins to spend. The onramp flow lets users buy USDC with a credit card and deliver it directly to their Crossmint wallet.

Onramp is a **UI flow, not a headless API**. Card authorization, 3DS challenges, and KYC checks all require the user to interact with a Crossmint-hosted component, the same way Apple Pay or Stripe Elements work. Raw card data and PII never reach your servers.

In this guide, you'll learn how to:

* Create a Crossmint order using a server action
* Use Crossmint's embedded checkout component to handle KYC, payment, and delivery automatically

<Snippet file="enterprise-feature-production.mdx" />

## Prerequisites

<Steps>
  <Step title="Install the SDK">
    Install the Crossmint client SDK:

    <CodeGroup>
      ```bash npm theme={null}
      npm install @crossmint/client-sdk-react-ui
      ```

      ```bash yarn theme={null}
      yarn add @crossmint/client-sdk-react-ui
      ```

      ```bash pnpm theme={null}
      pnpm add @crossmint/client-sdk-react-ui
      ```

      ```bash bun theme={null}
      bun add @crossmint/client-sdk-react-ui
      ```
    </CodeGroup>
  </Step>

  <Step title="Create API keys">
    Create a [server-side API key](/introduction/platform/api-keys/server-side) with the `orders.create` and `orders.read` scopes enabled.

    Create a [client-side API key](/introduction/platform/api-keys/client-side) for the embedded checkout component.

    In staging, all scopes are enabled by default.
  </Step>

  <Step title="Create a user wallet">
    Make sure the user has a Crossmint wallet. See [Create a User Wallet](/agents/payment-methods/stablecoin-wallets/create-user-wallet) if you have not done this yet.
  </Step>

  <Step title="Add environment variables">
    Add environment variables to your `.env.local`:

    ```sh .env.local theme={null}
    NEXT_PUBLIC_CROSSMINT_CLIENT_SIDE_API_KEY="_YOUR_CLIENT_API_KEY_"
    CROSSMINT_SERVER_SIDE_API_KEY="_YOUR_SERVER_API_KEY_"
    ```
  </Step>
</Steps>

## Steps

<Steps>
  <Step title="Create the server action">
    Create a server action that creates onramp orders via the Crossmint API. The recipient is the user's wallet address — funds are delivered straight to the wallet your agent is authorized on.

    ```typescript app/actions/createOrder.ts theme={null}
    "use server";

    const USDC_TOKEN_LOCATORS = {
        solanaDevnet: "solana:4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
        baseSepolia: "base-sepolia:0x036CbD53842c5426634e7929541eC2318f3dCF7e",
        stellarTestnet: "stellar:CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA",
    };

    interface CreateOrderParams {
        walletAddress: string;
        receiptEmail: string;
        amount: string;
        chain: "solanaDevnet" | "baseSepolia" | "stellarTestnet";
    }

    export async function createOrder({ walletAddress, receiptEmail, amount, chain }: CreateOrderParams) {
        const serverApiKey = process.env.CROSSMINT_SERVER_SIDE_API_KEY;
        if (serverApiKey == null) {
            throw new Error("CROSSMINT_SERVER_SIDE_API_KEY is not set");
        }

        const response = await fetch("https://staging.crossmint.com/api/2022-06-09/orders", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-api-key": serverApiKey,
            },
            body: JSON.stringify({
                lineItems: [
                    {
                        tokenLocator: USDC_TOKEN_LOCATORS[chain],
                        executionParameters: {
                            mode: "exact-in",
                            amount,
                        },
                    },
                ],
                payment: {
                    method: "card",
                    receiptEmail,
                },
                recipient: {
                    walletAddress,
                },
            }),
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || "Failed to create order");
        }

        return response.json();
    }
    ```
  </Step>

  <Step title="Build the onramp component">
    Create a client component that pulls the user's wallet from `useWallet()`, creates an order, and renders the embedded checkout. Because the agent is already authorized on the wallet, any USDC delivered here is immediately spendable by the agent.

    ```tsx app/components/OnrampCheckout.tsx theme={null}
    "use client";

    import { useState } from "react";
    import {
        CrossmintEmbeddedCheckout,
        useCrossmintAuth,
        useWallet,
    } from "@crossmint/client-sdk-react-ui";
    import { createOrder } from "../actions/createOrder";

    export default function OnrampCheckout() {
        const { wallet } = useWallet();
        const { user } = useCrossmintAuth();
        const [order, setOrder] = useState<{ orderId: string; clientSecret: string } | null>(null);
        const [amount, setAmount] = useState("5");
        const [isLoading, setIsLoading] = useState(false);

        async function handleSubmit() {
            if (!wallet || !user?.email) return;
            setIsLoading(true);
            try {
                const result = await createOrder({
                    walletAddress: wallet.address,
                    receiptEmail: user.email,
                    amount,
                    chain: "baseSepolia",
                });
                setOrder({ orderId: result.order.orderId, clientSecret: result.clientSecret });
            } catch (error) {
                console.error("Failed to create order:", error);
            } finally {
                setIsLoading(false);
            }
        }

        if (order != null) {
            return (
                <div className="max-w-[450px] w-full mx-auto p-6 rounded-xl bg-white">
                    <CrossmintEmbeddedCheckout
                        orderId={order.orderId}
                        clientSecret={order.clientSecret}
                        payment={{
                            receiptEmail: user?.email,
                            crypto: { enabled: false },
                            fiat: { enabled: true },
                            defaultMethod: "fiat",
                        }}
                    />
                </div>
            );
        }

        return (
            <div className="max-w-md mx-auto p-8 rounded-xl border border-gray-300 bg-white shadow-sm space-y-6">
                <h2 className="text-2xl font-semibold text-gray-900">Add funds to your wallet</h2>

                <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-900">Recipient Wallet</label>
                    <div className="w-full px-3 py-2 rounded-lg border border-gray-300 bg-gray-50 text-gray-900 text-sm font-mono break-all">
                        {wallet?.address ?? "Connect a wallet…"}
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-900">Amount (USD)</label>
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        className="w-full px-3 py-2 rounded-lg border border-gray-300 bg-white text-gray-900 text-sm"
                    />
                </div>

                <button
                    onClick={handleSubmit}
                    disabled={isLoading || !wallet || !user?.email}
                    className="w-full py-3 rounded-lg bg-black text-white font-medium hover:bg-gray-800 disabled:opacity-50 transition-colors"
                >
                    {isLoading ? "Creating Order…" : "Continue to Checkout"}
                </button>
            </div>
        );
    }
    ```

    The embedded checkout already runs inside the `CrossmintProvider` you set up to create the user's wallet, so no extra provider is needed here.
  </Step>

  <Step title="Add the component to your page">
    Drop `OnrampCheckout` into the page where the user funds their wallet — for example, right after authorizing the agent.

    ```tsx app/page.tsx theme={null}
    import OnrampCheckout from "./components/OnrampCheckout";

    export default function FundPage() {
        return (
            <main className="min-h-screen flex items-center justify-center">
                <OnrampCheckout />
            </main>
        );
    }
    ```

    When the user clicks **Continue to Checkout**, the server action creates an order and the embedded checkout component handles KYC, payment, and delivery automatically. As soon as USDC lands in the wallet, the agent can spend it.
  </Step>
</Steps>

<Tip>
  **Testing:** Use the test credit card number `4242 4242 4242 4242` with any future expiration date and any 3-digit CVC.
</Tip>

## Common Gotchas

<AccordionGroup>
  <Accordion title="Onramp delivers to the user wallet, not the agent">
    The recipient of the order is always the user's wallet address. The agent does not have its own balance — it spends from the user's wallet using its delegated server signer.
  </Accordion>

  <Accordion title="Use staging chains while testing">
    The token locators above target Base Sepolia, Solana Devnet, and Stellar Testnet. Switch to mainnet locators only after end-to-end staging tests pass.
  </Accordion>

  <Accordion title="The user is the payer, even if the agent triggers the flow">
    Card collection, 3DS, and KYC must be completed by the user in the embedded checkout. An agent cannot complete onramp on behalf of the user.
  </Accordion>
</AccordionGroup>

## What Is Next

<CardGroup cols={2}>
  <Card title="On-Chain Actions" icon="paper-plane" href="/agents/payment-methods/stablecoin-wallets/on-chain-actions">
    Once funded, send stablecoins and call contracts from your agent.
  </Card>

  <Card title="Save a Card" icon="credit-card" href="/agents/payment-methods/cards/save-card">
    Set up the card that will fund the wallet.
  </Card>
</CardGroup>
