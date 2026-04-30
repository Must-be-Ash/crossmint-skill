# React

> Create user wallets from your frontend in under 5 minutes

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/wallets/v0/quickstarts/react) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

<CardGroup cols={2}>
  <Snippet file="before-you-start.mdx" />

  <Card title="Wallets Quickstart" icon="github" iconType="duotone" href="https://github.com/Crossmint/wallets-quickstart">
    See a full working example.
  </Card>
</CardGroup>

<Steps>
  <Step title="Install the SDK">
    Run the following command to install the SDK:

    <Snippet file="client-sdk-react-ui-installation-cmd.mdx" />
  </Step>

  <Step title="Add the Crossmint providers to your app">
    Add the necessary Crossmint providers to your app. This example uses
    [Crossmint Auth](/authentication/introduction) but you can use
    [any authentication provider of your choice](/wallets/guides/bring-your-own-auth).

    With the current setup, a wallet will be created automatically on login.

    ```tsx providers.tsx theme={null}
    "use client";

    import {
        CrossmintProvider,
        CrossmintAuthProvider,
        CrossmintWalletProvider,
    } from "@crossmint/client-sdk-react-ui";

    export function Providers({
        children,
    }: {
        children: React.ReactNode;
    }) {
        return (
            <CrossmintProvider
                apiKey={process.env.NEXT_PUBLIC_CROSSMINT_API_KEY!}
            >
                <CrossmintAuthProvider
                    loginMethods={["email", "google"]}
                >
                    <CrossmintWalletProvider
                        createOnLogin={{
                            chain: "base-sepolia",
                            recovery: { type: "email" },
                        }}
                    >
                        {children}
                    </CrossmintWalletProvider>
                </CrossmintAuthProvider>
            </CrossmintProvider>
        );
    }
    ```

    For detailed configuration options, see the
    [React SDK Reference](/sdk-reference/wallets/react/providers#crossmintwalletprovider).
  </Step>

  <Step title="Display wallet info">
    Use the `useWallet` hook to access the wallet once the user is
    authenticated.

    ```tsx wallet-display.tsx theme={null}
    "use client";

    import { useWallet } from "@crossmint/client-sdk-react-ui";

    export function WalletDisplay() {
        const { wallet, status } = useWallet();

        if (status === "in-progress") {
            return <p>Creating wallet...</p>;
        }

        if (!wallet) {
            return <p>No wallet connected</p>;
        }

        return (
            <div>
                <p>Address: {wallet.address}</p>
                <p>Chain: {wallet.chain}</p>
            </div>
        );
    }
    ```
  </Step>

  <Step title="Check balances and fund the wallet">
    Query token balances and fund the wallet in staging.

    ```tsx balance-card.tsx theme={null}
    "use client";

    import { useWallet } from "@crossmint/client-sdk-react-ui";
    import { useState } from "react";

    const TOKENS = ["usdxm", "usdc"];

    export function BalanceCard() {
        const { wallet } = useWallet();
        const [balances, setBalances] =
            useState<Record<string, string>>({});

        const refreshBalance = async () => {
            if (!wallet) return;
            const res = await wallet.balances(TOKENS);
            const map: Record<string, string> = {};
            for (const t of res.tokens) {
                map[t.symbol] = t.amount;
            }
            setBalances(map);
        };

        const handleFund = async () => {
            if (!wallet) return;
            // Note: stagingFund() is for testing only - remove in production
            await wallet.stagingFund(10);
            await refreshBalance();
        };

        return (
            <div>
                {TOKENS.map((token) => (
                    <p key={token}>
                        {token.toUpperCase()}: {balances[token] ?? "—"}
                    </p>
                ))}
                <button onClick={handleFund}>
                    Fund 10 USDXM
                </button>
                <button onClick={refreshBalance}>
                    Refresh
                </button>
            </div>
        );
    }
    ```
  </Step>

  <Step title="Transfer tokens">
    Send tokens to another wallet address.

    ```tsx transfer-form.tsx theme={null}
    "use client";

    import { useWallet } from "@crossmint/client-sdk-react-ui";
    import { useState } from "react";

    export function TransferForm() {
        const { wallet } = useWallet();
        const [recipient, setRecipient] = useState("");
        const [amount, setAmount] = useState("");
        const [explorerUrl, setExplorerUrl] = useState("");

        const handleTransfer = async () => {
            if (!wallet || !recipient || !amount) return;
            try {
                const { explorerLink } = await wallet.send(
                    recipient,
                    "usdxm",
                    amount
                );
                setExplorerUrl(explorerLink);
                setRecipient("");
                setAmount("");
            } catch (error) {
                console.error("Transfer failed:", error);
            }
        };

        return (
            <div>
                <input
                    placeholder="Recipient address"
                    value={recipient}
                    onChange={(e) => setRecipient(e.target.value)}
                />
                <input
                    type="number"
                    placeholder="Amount"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                />
                <button
                    onClick={handleTransfer}
                    disabled={!recipient || !amount}
                >
                    Transfer
                </button>
                {explorerUrl && (
                    <a href={explorerUrl} target="_blank">
                        View transaction
                    </a>
                )}
            </div>
        );
    }
    ```
  </Step>

  <Step title="Render the app">
    Compose the providers and components in your app entry point.

    ```tsx app.tsx theme={null}
    "use client";

    import { Providers } from "./providers";
    import { WalletDisplay } from "./wallet-display";
    import { BalanceCard } from "./balance-card";
    import { TransferForm } from "./transfer-form";

    export default function Home() {
        return (
            <Providers>
                <WalletDisplay />
                <BalanceCard />
                <TransferForm />
            </Providers>
        );
    }
    ```
  </Step>
</Steps>

## Launching in Production

For production, some changes are required:

1. Create a developer account on the <a href="https://www.crossmint.com/console" target="_blank">production console</a>
2. Create a production client API key on the <a href="https://www.crossmint.com/console/projects/apiKeys" target="_blank">API Keys</a> page with the API scopes `users.create`, `users.read`, `wallets.read`, `wallets.create`, `wallets:transactions.create`, `wallets:transactions.sign`, `wallets:balance.read`, `wallets.fund`
3. Replace your test API key with the production key
4. **Use your own authentication provider**: For production applications, Crossmint recommends using [third-party authentication](/wallets/guides/bring-your-own-auth) with providers like Auth0, Firebase, or Supabase, rather than Crossmint Auth. Configure JWT authentication in the <a href="https://www.crossmint.com/console/projects/apiKeys" target="_blank">Crossmint Console</a> under API Keys > JWT Authentication.

## Learn More

<CardGroup cols={3}>
  <Card title="Check Balances" icon="money-bill-transfer" iconType="duotone" href="/wallets/guides/check-balances">
    Check the balance of a wallet.
  </Card>

  <Card title="Transfer Tokens" icon="coins" iconType="duotone" color="#1A5785" href="/wallets/guides/transfer-tokens">
    Send tokens between wallets.
  </Card>

  <Card title="Operational Signers" icon="key" iconType="duotone" color="#2156B9" href="/wallets/guides/signers/add-signers">
    Register operational signers on a wallet.
  </Card>
</CardGroup>

## Other Links

<CardGroup cols={2}>
  <Card title="API Reference" icon="terminal" color="#B56710" href="/api-reference/wallets/create-wallet">
    Deep dive into API reference docs.
  </Card>

  <Card title="Talk to an expert" icon="message" iconType="duotone" color="#ADD8E6" href="https://www.crossmint.com/contact/sales">
    Contact our sales team for support.
  </Card>
</CardGroup>
