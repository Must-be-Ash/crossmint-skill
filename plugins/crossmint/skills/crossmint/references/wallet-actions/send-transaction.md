# EVM

> Send transactions from your wallet

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/wallets/v0/guides/send-transaction-evm) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

## Prerequisites

* Ensure you have a wallet created.
* **Signer**: The signing wallet must be registered as a signer on the wallet. You can do this [at wallet creation](/wallets/guides/create-wallet) by passing `signers`, or afterward by [adding a signer](/wallets/guides/signers/add-signers).
* **API Key**: Ensure you have an API key with the scopes: `wallets:transactions.create`.

## What is sending a custom transaction?

Sending a custom transaction lets you interact with any smart contract on the blockchain beyond simple transfers. Common use cases include minting free tokens, claiming rewards, or registering for allowlists—all without needing to manage private keys yourself.

## Sending a Transaction

<Tabs>
  <Tab title="React">
    ```typescript theme={null}
    import { useWallet, EVMWallet } from '@crossmint/client-sdk-react-ui';

    const { wallet } = useWallet();

    const evmWallet = EVMWallet.from(wallet);

    // Replace with the target contract address
    const TARGET_CONTRACT = "0x...";
    // Replace with the calldata for your contract interaction
    const CALL_DATA = "0x...";

    const { hash, explorerLink } = await evmWallet.sendTransaction({
        to: TARGET_CONTRACT,
        value: BigInt(0),
        data: CALL_DATA,
    });
    ```

    See the [React SDK reference](/sdk-reference/wallets/react/hooks#wallet-methods) for more details.
  </Tab>

  <Tab title="Node.js">
    ```typescript theme={null}
    import { CrossmintWallets, createCrossmint, EVMWallet } from "@crossmint/wallets-sdk";

    const SERVER_API_KEY = process.env.SERVER_API_KEY!;
    const CROSSMINT_SIGNER_SECRET = process.env.CROSSMINT_SIGNER_SECRET!;
    // Replace with your wallet address
    const WALLET_ADDRESS = "0x...";
    // Replace with the target contract address
    const TARGET_CONTRACT = "0x...";
    // Replace with the calldata for your contract interaction
    const CALL_DATA = "0x...";

    const crossmint = createCrossmint({
        apiKey: SERVER_API_KEY,
    });

    const crossmintWallets = CrossmintWallets.from(crossmint);

    const wallet = await crossmintWallets.getWallet(
        WALLET_ADDRESS,
        { chain: "base-sepolia" }
    );

    await wallet.useSigner({ type: "server", secret: CROSSMINT_SIGNER_SECRET });

    const evmWallet = EVMWallet.from(wallet);

    try {
        const { hash, explorerLink } = await evmWallet.sendTransaction({
            to: TARGET_CONTRACT,
            value: BigInt(0),
            data: CALL_DATA,
        });
        console.log("Transaction sent:", hash, explorerLink);
    } catch (error) {
        console.error("Failed to send transaction:", error);
        throw error;
    }
    ```

    See the [SDK reference](/sdk-reference/wallets/typescript/classes/EVMWallet#sendtransaction) for all parameters and return types.
  </Tab>

  <Tab title="React Native">
    ```typescript theme={null}
    import { useWallet, EVMWallet } from '@crossmint/client-sdk-react-native-ui';

    const { wallet } = useWallet();

    const evmWallet = EVMWallet.from(wallet);

    // Replace with the target contract address
    const TARGET_CONTRACT = "0x...";
    // Replace with the calldata for your contract interaction
    const CALL_DATA = "0x...";

    const { hash, explorerLink } = await evmWallet.sendTransaction({
        to: TARGET_CONTRACT,
        value: BigInt(0),
        data: CALL_DATA,
    });
    ```

    See the [React Native SDK reference](/sdk-reference/wallets/react-native/hooks#wallet-methods) for more details.
  </Tab>

  <Tab title="Flutter">
    ```dart theme={null}
    import 'package:crossmint_flutter/crossmint_flutter_ui.dart';

    final controller = CrossmintWalletContext.of(context).requireWalletController;
    final evmWallet = controller.createEvmWallet();

    const targetContract = '0x...';
    const callData = '0x...';

    final tx = await evmWallet.sendTransaction(
      const CrossmintEvmTransactionRequest(
        calls: <CrossmintEvmTransactionCall>[
          CrossmintEvmTransactionCall(to: targetContract, value: '0', data: callData),
        ],
      ),
    );
    print('Transaction: ${tx.id}');
    ```

    See the [Flutter SDK reference](/sdk-reference/wallets/flutter/controllers#wallet-methods) for more details.
  </Tab>

  <Tab title="Swift">
    ```swift theme={null}
    import CrossmintClient
    import Wallet

    let sdk = CrossmintSDK.shared

    let wallet = try await sdk.crossmintWallets.getWallet(
        chain: .baseSepolia
    )

    let evmWallet = try EVMWallet.from(wallet: wallet)

    let result = try await evmWallet.sendTransaction(transaction)
    ```

    ### Parameters

    <ParamField path="transaction" type="EVMTransactionInput" required>
      The transaction to send.
    </ParamField>

    ### Returns

    <ParamField path="hash" type="string">
      The hash of the transaction.
    </ParamField>

    <ParamField path="explorerLink" type="string">
      The explorer link of the transaction.
    </ParamField>
  </Tab>

  <Tab title="REST">
    Transactions must be approved by one of the wallet's [signers](/wallets/concepts/signers).
    The SDK handles this automatically, but with the REST API you must [approve the transaction](/api-reference/wallets/approve-transaction) to complete it.

    <Steps>
      <Step title="Create the transaction">
        Call the [create transaction](/api-reference/wallets/create-transaction) endpoint.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets/<wallet-locator>/transactions \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: YOUR_API_KEY' \
              --data '{
                  "params": {
                      "calls": [{
                          "to": "0x...",
                          "value": "0x",
                          "data": "0x..."
                      }],
                      "chain": "base-sepolia",
                      "signer": "server:YOUR_SERVER_SIGNER_ADDRESS"
                  }
              }'
          ```

          ```js Node.js theme={null}
          // Replace with your wallet locator
          const WALLET_LOCATOR = "YOUR_WALLET_LOCATOR";
          const url = `https://staging.crossmint.com/api/2025-06-09/wallets/${WALLET_LOCATOR}/transactions`;

          const SERVER_API_KEY = process.env.SERVER_API_KEY;
          // Replace with your server signer address
          const SIGNER_ADDRESS = "YOUR_SERVER_SIGNER_ADDRESS";

          const payload = {
              params: {
                  calls: [{
                      to: "0x...",
                      value: "0x",
                      data: "0x..."
                  }],
                  chain: "base-sepolia",
                  signer: `server:${SIGNER_ADDRESS}`
              }
          };

          const options = {
              method: 'POST',
              headers: {
                  'X-API-KEY': SERVER_API_KEY,
                  'Content-Type': 'application/json'
              },
              body: JSON.stringify(payload)
          };

          try {
              const response = await fetch(url, options);
              const data = await response.json();
              console.log(data);
          } catch (error) {
              console.error(error);
          }
          ```

          ```python Python theme={null}
          import os
          import requests

          SERVER_API_KEY = os.environ["SERVER_API_KEY"]
          # Replace with your wallet locator
          WALLET_LOCATOR = "YOUR_WALLET_LOCATOR"
          # Replace with your server signer address
          SIGNER_ADDRESS = "YOUR_SERVER_SIGNER_ADDRESS"

          url = f"https://staging.crossmint.com/api/2025-06-09/wallets/{WALLET_LOCATOR}/transactions"

          payload = {
              "params": {
                  "calls": [{
                      "to": "0x...",
                      "value": "0x",
                      "data": "0x..."
                  }],
                  "chain": "base-sepolia",
                  "signer": f"server:{SIGNER_ADDRESS}"
              }
          }
          headers = {
              "X-API-KEY": SERVER_API_KEY,
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)

          print(response.json())
          ```
        </CodeGroup>

        See the [API reference](/api-reference/wallets/create-transaction) for more details.
      </Step>

      <Step title="Choose your signer type">
        The next steps depend on which signer type you specified in the previous step.

        <Tabs>
          <Tab title="Server Signer">
            [Server](/wallets/guides/signers/server-signer) signers derive a private key from your signer secret using HKDF-SHA256 and sign transactions locally.

            When using the **SDK**, signing and approval are handled automatically — no additional steps are needed.

            When using the **REST API** directly, you must:

            1. Derive the signing key from your signer secret (scoped to your project, environment, and chain). See the <a href="https://github.com/Crossmint/crossmint-sdk/blob/main/packages/wallets/src/signers/server/helpers/derive-server-signer.ts" target="_blank" rel="noopener">derive-server-signer helper</a> for a reference implementation.
            2. Sign the approval message returned from the transaction creation step.
            3. Submit the signature via the [approve transaction](/api-reference/wallets/approve-transaction) endpoint.

            <Warning>
              Crossmint recommends using the <a href="https://www.npmjs.com/package/@crossmint/wallets-sdk" target="_blank" rel="noopener">Wallets SDK</a> for server signer flows. The SDK handles key derivation and signing automatically.
            </Warning>

            See the [Server Signer guide](/wallets/guides/signers/server-signer) for full configuration and setup details.
          </Tab>

          <Tab title="Device Signer">
            [Device](/wallets/guides/signers/device-signer) signers generate a P256 keypair inside the device's secure hardware (Secure Enclave, Android Keystore, or browser Web Crypto API). Because the private key never leaves the device, device signers are **client-side only** and cannot be used directly with the REST API.

            <Warning>
              Crossmint recommends using the React, React Native, or Swift SDK for device signer flows. The SDK handles device key generation, storage, and signing automatically.
            </Warning>

            See the [Device Signer guide](/wallets/guides/signers/device-signer) for setup instructions.
          </Tab>

          <Tab title="External Wallet">
            For [External Wallet](/wallets/guides/signers/add-signers) signers, you must manually sign the approval message and submit it via the API. The response from Step 1 includes a pending approval with a `message` field that must be signed exactly as returned.

            From the previous step's response, extract:

            * `id` - The transaction ID (used in the next step)
            * `approvals.pending[0].message` - The hex message to sign

            Sign the message using your external wallet. The message is a raw hex string and must be signed exactly as returned. Here's an example using an EVM wallet with [Viem](https://viem.sh/):

            ```typescript theme={null}
            import { privateKeyToAccount } from "viem/accounts";

            // The message from tx.approvals.pending[0].message
            const messageToSign = "<messageFromResponse>";

            // Sign the message exactly as returned (raw hex)
            const account = privateKeyToAccount(`0x${"<privateKey>"}`);
            const signature = await account.signMessage({
                message: { raw: messageToSign },
            });
            ```
          </Tab>

          <Tab title="Email & Phone">
            [Email and phone](/wallets/guides/signers/configure-recovery) signers require client-side OTP verification and key derivation, which the Crossmint SDK handles automatically. While REST API signing is technically possible, Crossmint does not recommend it because you would still need client-side SDK integration for the signing step.

            <Warning>
              Crossmint recommends using the React, React Native, Swift, or Node.js SDK examples instead. The SDK handles the full signing flow for email and phone signers.
            </Warning>
          </Tab>

          <Tab title="Passkey">
            [Passkey](/wallets/guides/signers/add-signers) signers use WebAuthn for biometric or password manager authentication, which requires browser interaction. While REST API signing is technically possible, Crossmint does not recommend it because you would still need client-side SDK integration for the WebAuthn signing step.

            <Warning>
              Crossmint recommends using the React, React Native, Swift, or Node.js SDK examples instead. The SDK handles the full passkey signing flow automatically.
            </Warning>
          </Tab>
        </Tabs>
      </Step>

      <Step title="Submit the approval">
        <Note>
          Skip this step if using the **SDK with a server signer** — the SDK handles signing and approval automatically.
        </Note>

        Call the [approve transaction](/api-reference/wallets/approve-transaction) endpoint with the signature from Step 2 and the transaction ID from Step 1.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets/<walletAddress>/transactions/<txId>/approvals \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: <x-api-key>' \
              --data '{
                  "approvals": [{
                      "signer": "external-wallet:<externalWalletAddress>",
                      "signature": "<signature>"
                  }]
              }'
          ```

          ```js Node.js theme={null}
          const url = 'https://staging.crossmint.com/api/2025-06-09/wallets/<walletAddress>/transactions/<txId>/approvals';

          const payload = {
              approvals: [{
                  signer: "external-wallet:<externalWalletAddress>",
                  signature: "<signature>"
              }]
          };

          const options = {
              method: 'POST',
              headers: {
                  'X-API-KEY': '<x-api-key>',
                  'Content-Type': 'application/json'
              },
              body: JSON.stringify(payload)
          };

          try {
              const response = await fetch(url, options);
              const data = await response.json();
              console.log(data);
          } catch (error) {
              console.error(error);
          }
          ```

          ```python Python theme={null}
          import requests

          url = "https://staging.crossmint.com/api/2025-06-09/wallets/<walletAddress>/transactions/<txId>/approvals"

          payload = {
              "approvals": [{
                  "signer": "external-wallet:<externalWalletAddress>",
                  "signature": "<signature>"
              }]
          }
          headers = {
              "X-API-KEY": "<x-api-key>",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)

          print(response.json())
          ```
        </CodeGroup>

        See the [API reference](/api-reference/wallets/approve-transaction) for more details.
      </Step>
    </Steps>
  </Tab>
</Tabs>
