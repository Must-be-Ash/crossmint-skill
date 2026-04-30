# Authorize the Agent

> Grant your agent delegated control over the user's wallet.

## Introduction

To let the agent move funds from the user's wallet, you create a **signer** for the agent and add it to the wallet. A signer is just a key that can authorize transactions — the agent gets its own, separate from the user's.

You add the signer in two parts so the user stays in control:

1. **On your server**, you create the signer and register it on the wallet as *pending*. The signer's secret stays in your backend and never reaches the browser or the agent.
2. **On the client**, the user approves the new signer with a one-time email code. Only after this step can the agent sign anything.

Once approved, the agent can transact within the limits you set — and the user can revoke it at any time.

## Prerequisites

* A user wallet. See [Server signer setup](/wallets/guides/signers/server-signer#hkdf-sha256-key-derivation-tool) if you have not done this yet.
* A Crossmint **server-side** API key from the <a href="https://staging.crossmint.com/console/projects/apiKeys" target="_blank">Crossmint Console</a>.
* The user must be authenticated and signed in to your app.

## Steps

<Steps>
  <Step title="Generate and store the signer secret">
    The server signer is backed by a 32-byte secret. Generate one with [the signer secret generator](/agents/stablecoin-wallet-quickstart#setup) and store it only as a backend environment variable.

    ```bash theme={null}
    CROSSMINT_SERVER_SIDE_API_KEY=sk_staging_...
    CROSSMINT_SIGNER_SECRET=your-64-char-hex-secret
    ```

    <Warning>
      Anyone who holds `CROSSMINT_SIGNER_SECRET` can sign on behalf of every wallet it has been authorized on. Never commit it, never expose it to the client, and rotate it if you suspect leakage.
    </Warning>
  </Step>

  <Step title="Register the signer from the server">
    Use a server action (or any server-only handler) to call `addSigner` in `prepareOnly` mode. The secret is read from the environment and never sent over the wire.

    ```typescript theme={null}
    "use server";

    import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

    export async function prepareServerSigner({ walletAddress }: { walletAddress: string }) {
        const crossmint = createCrossmint({
            apiKey: process.env.CROSSMINT_SERVER_SIDE_API_KEY,
        });
        const wallets = CrossmintWallets.from(crossmint);
        const wallet = await wallets.getWallet(walletAddress, { chain: "base-sepolia" });

        const { locator, signatureId } = await wallet.addSigner(
            { type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET },
            { prepareOnly: true }
        );

        return { locator, signatureId };
    }
    ```

    `prepareOnly: true` is what makes this safe. Without it, the SDK would auto-approve using whatever signer is active, which on the server is the server signer itself — the user would never see a prompt.
  </Step>

  <Step title="Approve from the client">
    On the client, call the server action and then ask the SDK to approve the pending signature with the user's recovery signer. This is the step that triggers the email code.

    ```tsx theme={null}
    "use client";

    import { useWallet, useCrossmintAuth } from "@crossmint/client-sdk-react-ui";
    import { prepareServerSigner } from "@/app/actions/add-server-signer";

    export function AuthorizeAgent() {
        const { wallet } = useWallet();
        const { user } = useCrossmintAuth();

        const handleAuthorize = async () => {
            if (!wallet || !user?.email) return;

            const { signatureId } = await prepareServerSigner({ walletAddress: wallet.address });

            await wallet.useSigner({ type: "email", email: user.email });
            await wallet.approve({ signatureId });
        };

        return <button onClick={handleAuthorize}>Authorize agent</button>;
    }
    ```

    Once the user completes the verification, the server signer becomes an authorized signer on the wallet. Verify by calling `wallet.signers()` — you should see an entry with `type: "server"`.
  </Step>
</Steps>

## Revoking the Agent

Once authorized, the agent can be revoked at any time. See [Remove Agent Access](/agents/payment-methods/stablecoin-wallets/remove-agent-access).

## Common Gotchas

<AccordionGroup>
  <Accordion title="Always pass `prepareOnly: true` from the server">
    If you omit it, the server signer signs its own authorization and the user never approves. The pending signature step is what gives the user veto power.
  </Accordion>

  <Accordion title="The signer secret must stay server-side">
    Anyone holding the secret can sign for every wallet it has been authorized on. Treat it like a database password — environment variables only, never the client bundle.
  </Accordion>
</AccordionGroup>

## Next Steps

<CardGroup cols={2}>
  <Card title="Onramp Funds" icon="arrow-down-to-line" href="/agents/payment-methods/stablecoin-wallets/onramp-add-funds">
    Add stablecoin balance to the user's wallet so the authorized agent can start spending.
  </Card>

  <Card title="Server Signer Deep Dive" icon="server" href="/wallets/guides/signers/server-signer">
    Full reference for the server signer, secret rotation, and multi-tenant patterns.
  </Card>
</CardGroup>
