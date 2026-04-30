# Create a User Wallet

> Create a non-custodial wallet owned by your end user, with email or passkey recovery.

## Introduction

The user wallet is the root of every agent stablecoin flow. It is **non-custodial** and owned by the end user, with an **email** (or passkey) recovery signer that stays in the user's control. Your agent is later authorized to use the wallet as a [signer](/agents/payment-methods/stablecoin-wallets/authorize-agent) with explicit spending limits, and that access can be revoked at any time.

Subsequent logins from the same user return the same wallet — creation is idempotent.

## Prerequisites

* A staging Crossmint client API key from the <a href="https://staging.crossmint.com/console/projects/apiKeys" target="_blank">Crossmint Console</a>. In staging, all scopes are enabled by default.
* The user must be authenticated. If you have not set up authentication, see the [Agents overview](/agents/overview) first.

## Steps

<Steps>
  <Step title="Install the SDK">
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

  <Step title="Wrap your app with the Crossmint providers">
    Set up `CrossmintProvider`, `CrossmintAuthProvider`, and `CrossmintWalletProvider` at the root of your app. Pass `createOnLogin` to `CrossmintWalletProvider` so the SDK creates the user's wallet automatically as soon as they sign in, with an email-recovery.

    ```tsx theme={null}
    "use client";

    import {
        CrossmintAuthProvider,
        CrossmintProvider,
        CrossmintWalletProvider,
    } from "@crossmint/client-sdk-react-ui";

    export default function RootLayout({ children }: { children: React.ReactNode }) {
        return (
            <CrossmintProvider apiKey={process.env.NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY}>
                <CrossmintAuthProvider loginMethods={["email", "google"]}>
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
  </Step>

  <Step title="Read the wallet from any component">
    Use `useWallet()` anywhere below the provider to access the wallet. The hook exposes a `status` field you can use to render a loading state during creation.

    ```tsx theme={null}
    "use client";

    import { useWallet } from "@crossmint/client-sdk-react-ui";

    export function WalletSection() {
        const { wallet, status } = useWallet();

        if (status === "in-progress" || status === "not-loaded") {
            return <p>Creating wallet…</p>;
        }

        return <code>{wallet?.address}</code>;
    }
    ```

    When `status` is `loaded`, `wallet.address` is the user's wallet address and the wallet is ready for delegation.
  </Step>
</Steps>

## Manual Creation (Non-React or Server-Side)

If you are not using the React SDK — for example, creating the wallet server-side from a custom auth backend — use the wallets SDK directly:

```typescript theme={null}
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({
    apiKey: process.env.CROSSMINT_SERVER_SIDE_API_KEY,
});
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.createWallet({
    chain: "base-sepolia",
    owner: `userId:${userId}`,
    signer: { type: "email", email: userEmail },
});
```

`owner` scopes the wallet to your authenticated user. Pass the same identifier on subsequent `getWallet` calls to resolve it.

## Common Gotchas

<AccordionGroup>
  <Accordion title="Calling createOnLogin twice for the same user is safe">
    Wallet creation is idempotent — repeated calls return the same wallet. You do not need to guard against double-creation in your UI.
  </Accordion>

  <Accordion title="The recovery signer cannot be removed later">
    The signer chosen at creation time is the wallet's root. Agents are added on top as scoped delegates and can be revoked, but the root recovery signer is permanent.
  </Accordion>

  <Accordion title="`owner` is required for server-side creation">
    On the React SDK, the user is identified by the auth provider's session. On the server, you must explicitly scope ownership with `owner: userId:<id>` so the wallet resolves correctly on later `getWallet` calls.
  </Accordion>
</AccordionGroup>

## What Is Next

With the user's wallet created, the next step is to add your agent as a signer so it can sign on the user's behalf.

Continue to [Authorize the Agent](/agents/payment-methods/stablecoin-wallets/authorize-agent).

For a full app you can clone and test end-to-end, see the [Stablecoin Wallet Quickstart](/agents/stablecoin-wallet-quickstart).
