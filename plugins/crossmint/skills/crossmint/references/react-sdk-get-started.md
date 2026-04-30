# Get Started

> Installation and setup for the React SDK reference for Crossmint wallets

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/sdk-reference/wallets/v0/react/get-started) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

### Latest React SDK version - <a href="https://www.npmjs.com/package/@crossmint/client-sdk-react-ui" target="_blank" rel="noopener" style={{display: "inline-block", verticalAlign: "middle", textDecoration: "none", borderBottom: "none"}}><img src="https://img.shields.io/npm/v/@crossmint/client-sdk-react-ui" alt="npm" style={{display: "inline-block", verticalAlign: "middle", margin: 0}} noZoom /></a>

The Crossmint React SDK (`@crossmint/client-sdk-react-ui`) provides React components and hooks for integrating Crossmint wallets into your application.

## Installation

<Snippet file="client-sdk-react-ui-installation-cmd.mdx" />

## Provider Setup

Wrap your application with the required providers:

```tsx theme={null}
import {
    CrossmintProvider,
    CrossmintWalletProvider,
} from "@crossmint/client-sdk-react-ui";

function App() {
    return (
        <CrossmintProvider apiKey="YOUR_CLIENT_API_KEY">
            <CrossmintWalletProvider
                createOnLogin={{
                    chain: "base-sepolia",
                    recovery: { type: "email" },
                }}
            >
                {/* Your app components */}
            </CrossmintWalletProvider>
        </CrossmintProvider>
    );
}
```

## Quick Example

Once providers are set up, use hooks to access wallet state:

```tsx theme={null}
import { useWallet } from "@crossmint/client-sdk-react-ui";

function WalletInfo() {
    const { wallet, status } = useWallet();

    if (status === "in-progress") return <p>Loading wallet...</p>;
    if (!wallet) return <p>No wallet connected</p>;

    return (
        <div>
            <p>Address: {wallet.address}</p>
            <p>Chain: {wallet.chain}</p>
        </div>
    );
}
```

## Next Steps

* [Providers](/sdk-reference/wallets/react/providers) — Configure providers and their options
* [Hooks](/sdk-reference/wallets/react/hooks) — Access SDK state via React hooks
* [Components](/sdk-reference/wallets/react/components) — Drop-in UI components
* [Wallets SDK Reference](/sdk-reference/wallets/typescript/classes/Wallet) — Complete wallet method documentation
