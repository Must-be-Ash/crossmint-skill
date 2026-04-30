# Node.js

> Create and manage wallets from your backend in under 5 minutes

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/wallets/v0/quickstarts/nodejs) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

<CardGroup cols={2}>
  <Snippet file="before-you-start.mdx" />
</CardGroup>

<Steps>
  <Step title="Install the SDK">
    Run the following command to install the SDK:

    <Snippet file="wallets-sdk-installation-cmd.mdx" />
  </Step>

  <Step title="Create a wallet with a server signer">
    The server signer uses a secret key you provide to derive a
    blockchain address deterministically. The same secret always
    produces the same address.

    <Note>
      Before creating a wallet, you need a signer secret. Generate one using the [key generation tool](/wallets/guides/signers/server-signer#hkdf-sha256-key-derivation-tool) or [programmatically](/wallets/guides/signers/server-signer#generate-your-own-key-programmatically), then store it as an environment variable (e.g. `SIGNER_SECRET`). See the [Server Signer guide](/wallets/guides/signers/server-signer) for full details.
    </Note>

    See all supported chains [here](/introduction/supported-chains).

    ```typescript index.ts theme={null}
    import {
        CrossmintWallets,
        createCrossmint,
    } from "@crossmint/wallets-sdk";

    const crossmint = createCrossmint({
        apiKey: "YOUR_SERVER_API_KEY",
    });

    const wallets = CrossmintWallets.from(crossmint);

    const wallet = await wallets.createWallet({
        chain: "base-sepolia",
        recovery: {
            type: "server",
            secret: process.env.SIGNER_SECRET!, // set in your .env file
        },
    });

    console.log("Wallet address:", wallet.address);
    ```

    <Note>
      The `secret` is never sent to Crossmint. The SDK derives the
      blockchain address locally from the secret and only sends the
      address to the API.
    </Note>
  </Step>

  <Step title="Check balances">
    ```typescript check-balance.ts theme={null}
    // Assumes `wallet` was created in the wallet creation step above
    const balances = await wallet.balances(["usdc", "usdxm"]);

    for (const token of balances.tokens) {
        console.log(`${token.symbol}: ${token.amount}`);
    }
    ```
  </Step>

  <Step title="Transfer tokens">
    ```typescript transfer.ts theme={null}
    // Assumes `wallet` was created in the wallet creation step above
    const tx = await wallet.send(
        "RECIPIENT_ADDRESS",
        "usdxm",
        "1"
    );

    console.log("Explorer:", tx.explorerLink);
    ```
  </Step>
</Steps>

## Launching in Production

For production, some changes are required:

1. Create a developer account on the <a href="https://www.crossmint.com/console" target="_blank">production console</a>
2. Create a production server API key on the <a href="https://www.crossmint.com/console/projects/apiKeys" target="_blank">API Keys</a> page with the API scopes `users.create`, `users.read`, `wallets.read`, `wallets.create`, `wallets:transactions.create`, `wallets:transactions.sign`, `wallets:balance.read`, `wallets.fund`
3. Replace your test API key with the production key

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
