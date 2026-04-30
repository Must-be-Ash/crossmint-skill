# EVM

> Sign messages from your wallet

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/wallets/v0/guides/sign-message-evm) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

## Prerequisites

* Ensure you have a wallet created.
* **API Key**: Ensure you have an API key with the scopes: `wallets:signatures.create`.

<Warning>
  If you are signing with an [operational signer](/wallets/guides/signers/add-signers), the wallet must have executed at least one transaction before signatures will work. This is because the wallet needs to be deployed onchain first.
</Warning>

## Signing a Message

<Tabs>
  <Tab title="React">
    ```typescript theme={null}
    import { useWallet, EVMWallet } from '@crossmint/client-sdk-react-ui';

    const { wallet } = useWallet();

    const evmWallet = EVMWallet.from(wallet);

    const signedMessage = await evmWallet.signMessage({ message: "Hello, world!" });
    ```

    See the [React SDK reference](/sdk-reference/wallets/react/hooks#wallet-methods) for more details.
  </Tab>

  <Tab title="Node.js">
    ```typescript theme={null}
    import { CrossmintWallets, createCrossmint, EVMWallet } from "@crossmint/wallets-sdk";

    const crossmint = createCrossmint({
        apiKey: "<your-server-api-key>",
    });

    const crossmintWallets = CrossmintWallets.from(crossmint);

    const wallet = await crossmintWallets.getWallet(
        "email:user@example.com:evm",
        { chain: "base-sepolia" }
    );

    await wallet.useSigner({ type: "email", email: "user@example.com" });

    const evmWallet = EVMWallet.from(wallet);

    const signedMessage = await evmWallet.signMessage({ message: "Hello, world!" });
    ```

    ### Parameters

    <ParamField path="message" type="string" required>
      The message to sign.
    </ParamField>

    ### Returns

    <ParamField path="signature" type="string">
      The signature of the message.
    </ParamField>
  </Tab>

  <Tab title="React Native">
    ```typescript theme={null}
    import { useWallet, EVMWallet } from '@crossmint/client-sdk-react-native-ui';

    const { wallet } = useWallet();

    const evmWallet = EVMWallet.from(wallet);

    const signedMessage = await evmWallet.signMessage({ message: "Hello, world!" });
    ```

    See the [React Native SDK reference](/sdk-reference/wallets/react-native/hooks#wallet-methods) for more details.
  </Tab>

  <Tab title="Flutter">
    ```dart theme={null}
    import 'package:crossmint_flutter/crossmint_flutter_ui.dart';

    final controller = CrossmintWalletContext.of(context).requireWalletController;
    final evmWallet = controller.createEvmWallet();

    final signature = await evmWallet.signMessage('Hello, world!');
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

    let signature = try await evmWallet.signMessage("Hello, world!")
    ```

    ### Parameters

    <ParamField path="message" type="string" required>
      The message to sign.
    </ParamField>

    ### Returns

    <ParamField path="signature" type="string">
      The signature of the message.
    </ParamField>
  </Tab>

  <Tab title="REST">
    Signatures must be approved by one of the wallet's [signers](/wallets/concepts/signers).
    The SDK handles this automatically, but with the REST API you must [approve the signature](/api-reference/wallets/approve-signature) to complete it.

    <Steps>
      <Step title="Create the signature">
        Call the [create signature](/api-reference/wallets/create-signature) endpoint.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: <x-api-key>' \
              --data '{
                  "type": "message",
                  "params": {
                      "message": "Hello, world!",
                      "signer": "email:user@example.com",
                      "chain": "base-sepolia"
                  }
              }'
          ```

          ```js Node.js theme={null}
          const url = 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures';

          const payload = {
              type: "message",
              params: {
                  message: "Hello, world!",
                  signer: "email:user@example.com",
                  chain: "base-sepolia"
              }
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

          url = "https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures"

          payload = {
              "type": "message",
              "params": {
                  "message": "Hello, world!",
                  "signer": "email:user@example.com",
                  "chain": "base-sepolia"
              }
          }
          headers = {
              "X-API-KEY": "<x-api-key>",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)

          print(response.json())
          ```
        </CodeGroup>

        See the [API reference](/api-reference/wallets/create-signature) for more details.
      </Step>

      <Step title="Sign the approval returned in the response">
        <Note>
          If you are using an `api-key` as the recovery signer (admin signer) you can skip the following steps.
        </Note>

        Sign the approval message field returned in the response inside `signature.approvals` using the signer.
      </Step>

      <Step title="Approve the signature">
        Call the [approve signature](/api-reference/wallets/approve-signature) endpoint using the signature from the previous step and the signature id returned in the call from Step 1.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures/91e90094-9fe0-43a7-bab6-e5725767a3ad/approvals \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: <x-api-key>' \
              --data '{
                  "approvals": [{
                      "signer": "email:user@example.com",
                      "signature": "0x1234567890abcdef..."
                  }]
              }'
          ```

          ```js Node.js theme={null}
          const url = 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures/91e90094-9fe0-43a7-bab6-e5725767a3ad/approvals';

          const payload = {
              approvals: [{
                  signer: "email:user@example.com",
                  signature: "0x1234567890abcdef..."
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

          url = "https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures/91e90094-9fe0-43a7-bab6-e5725767a3ad/approvals"

          payload = {
              "approvals": [{
                  "signer": "email:user@example.com",
                  "signature": "0x1234567890abcdef..."
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

        See the [API reference](/api-reference/wallets/approve-signature) for more details.
      </Step>
    </Steps>
  </Tab>
</Tabs>

## Signing Typed Data

<Tabs>
  <Tab title="React">
    ```typescript theme={null}
    import { useWallet, EVMWallet } from '@crossmint/client-sdk-react-ui';

    const { wallet } = useWallet();

    const evmWallet = EVMWallet.from(wallet);
    const typedData = {
        "types": {
            "EIP712Domain": [{
                "name": "name",
                "type": "string"
            }],
        },
        "primaryType": "Mail",
        "domain": {
            "name": "example.com",
            "version": "1"
        },
        "message": {
            "from": {
                "name": "John Doe"
            },
            "to": {
                "name": "Jane Doe"
            },
            "contents": "Hello, world!"
        }
    };
    const signedMessage = await evmWallet.signTypedData(typedData);
    ```

    See the [React SDK reference](/sdk-reference/wallets/react/hooks#wallet-methods) for more details.
  </Tab>

  <Tab title="Node.js">
    ```typescript theme={null}
    import { CrossmintWallets, createCrossmint, EVMWallet } from "@crossmint/wallets-sdk";

    const crossmint = createCrossmint({
        apiKey: "<your-server-api-key>",
    });

    const crossmintWallets = CrossmintWallets.from(crossmint);

    const wallet = await crossmintWallets.getWallet(
        "email:user@example.com:evm",
        { chain: "base-sepolia" }
    );

    await wallet.useSigner({ type: "email", email: "user@example.com" });

    const evmWallet = EVMWallet.from(wallet);

    const typedData = {
        "types": {
            "EIP712Domain": [{
                "name": "name",
                "type": "string"
            }],
        },
        "primaryType": "Mail",
        "domain": {
            "name": "example.com",
            "version": "1"
        },
        "message": {
            "from": {
                "name": "John Doe"
            },
            "to": {
                "name": "Jane Doe"
            },
            "contents": "Hello, world!"
        }
    };
    const signedMessage = await evmWallet.signTypedData(typedData);
    ```
  </Tab>

  <Tab title="React Native">
    ```typescript theme={null}
    import { useWallet, EVMWallet } from '@crossmint/client-sdk-react-native-ui';

    const { wallet } = useWallet();

    const evmWallet = EVMWallet.from(wallet);

    const typedData = {
        "types": {
            "EIP712Domain": [{
                "name": "name",
                "type": "string"
            }],
        },
        "primaryType": "Mail",
        "domain": {
            "name": "example.com",
            "version": "1"
        },
        "message": {
            "from": {
                "name": "John Doe"
            },
            "to": {
                "name": "Jane Doe"
            },
            "contents": "Hello, world!"
        }
    };
    const signedMessage = await evmWallet.signTypedData(typedData);
    ```

    See the [React Native SDK reference](/sdk-reference/wallets/react-native/hooks#wallet-methods) for more details.
  </Tab>

  <Tab title="Flutter">
    ```dart theme={null}
    import 'package:crossmint_flutter/crossmint_flutter_ui.dart';

    final controller = CrossmintWalletContext.of(context).requireWalletController;
    final evmWallet = controller.createEvmWallet();

    final typedData = CrossmintTypedData(
      raw: const <String, Object?>{
        'types': <String, Object?>{
          'EIP712Domain': <Map<String, Object?>>[
            <String, Object?>{'name': 'name', 'type': 'string'},
          ],
        },
        'primaryType': 'Mail',
        'domain': <String, Object?>{
          'name': 'example.com',
          'version': '1',
          'chainId': 84532,
          'verifyingContract': '0x...',
        },
        'message': <String, Object?>{
          'from': <String, Object?>{'name': 'John Doe'},
          'to': <String, Object?>{'name': 'Jane Doe'},
          'contents': 'Hello, world!',
        },
      },
    );
    final signature = await evmWallet.signTypedData(typedData);
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

    let signature = try await evmWallet.signTypedData(typedData)
    ```

    ### Parameters

    <ParamField path="typedData" type="TypedData" required>
      The typed data to sign.
    </ParamField>

    ### Returns

    <ParamField path="signature" type="string">
      The signature of the message.
    </ParamField>
  </Tab>

  <Tab title="REST">
    Signatures must be approved by one of the wallet's [signers](/wallets/concepts/signers).
    The SDK handles this automatically, but with the REST API you must [approve the signature](/api-reference/wallets/approve-signature) to complete it.

    <Steps>
      <Step title="Create the signature">
        Call the [create signature](/api-reference/wallets/create-signature) endpoint.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: <x-api-key>' \
              --data '{
                  "type": "typed-data",
                  "params": {
                      "typedData": {
                          "types": {
                              "EIP712Domain": [{
                                  "name": "name",
                                  "type": "string"
                              }],
                          },
                          "primaryType": "Mail",
                          "domain": {
                              "name": "example.com",
                              "version": "1"
                          },
                          "message": {
                              "from": {
                                  "name": "John Doe"
                              },
                              "to": {
                                  "name": "Jane Doe"
                              },
                              "contents": "Hello, world!"
                          }
                      },
                      "signer": "email:user@example.com",
                      "chain": "base-sepolia"
                  }
              }'
          ```

          ```js Node.js theme={null}
          const url = 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures';

          const payload = {
              type: "typed-data",
              params: {
                  typedData: {
                      types: {
                          EIP712Domain: [{
                              name: "name",
                              type: "string"
                          }]
                      },
                      primaryType: "Mail",
                      domain: {
                          name: "example.com",
                          version: "1"
                      },
                      message: {
                          from: {
                              name: "John Doe"
                          },
                          to: {
                              name: "Jane Doe"
                          },
                          contents: "Hello, world!"
                      }
                  },
                  signer: "email:user@example.com",
                  chain: "base-sepolia"
              }
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

          url = "https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures"

          payload = {
              "type": "typed-data",
              "params": {
                  "typedData": {
                      "types": {
                          "EIP712Domain": [{
                              "name": "name",
                              "type": "string"
                          }],
                      },
                      "primaryType": "Mail",
                      "domain": {
                          "name": "example.com",
                          "version": "1"
                      },
                      "message": {
                          "from": {
                              "name": "John Doe"
                          },
                          "to": {
                              "name": "Jane Doe"
                          },
                          "contents": "Hello, world!"
                      }
                  },
                  "signer": "email:user@example.com",
                  "chain": "base-sepolia"
              }
          }
          headers = {
              "X-API-KEY": "<x-api-key>",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)

          print(response.json())
          ```
        </CodeGroup>

        See the [API reference](/api-reference/wallets/create-signature) for more details.
      </Step>

      <Step title="Sign the approval returned in the response">
        <Note>
          If you are using an `api-key` as the recovery signer (admin signer) you can skip the following steps.
        </Note>

        Sign the approval message field returned in the response inside `signature.approvals` using the signer.
      </Step>

      <Step title="Approve the signature">
        Call the [approve signature](/api-reference/wallets/approve-signature) endpoint using the signature from the previous step and the signature id returned in the call from Step 1.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures/91e90094-9fe0-43a7-bab6-e5725767a3ad/approvals \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: <x-api-key>' \
              --data '{
                  "approvals": [{
                      "signer": "email:user@example.com",
                      "signature": "0x1234567890abcdef..."
                  }]
              }'
          ```

          ```js Node.js theme={null}
          const url = 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures/91e90094-9fe0-43a7-bab6-e5725767a3ad/approvals';

          const payload = {
              approvals: [{
                  signer: "email:user@example.com",
                  signature: "0x1234567890abcdef..."
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

          url = "https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/signatures/91e90094-9fe0-43a7-bab6-e5725767a3ad/approvals"

          payload = {
              "approvals": [{
                  "signer": "email:user@example.com",
                  "signature": "0x1234567890abcdef..."
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

        See the [API reference](/api-reference/wallets/approve-signature) for more details.
      </Step>
    </Steps>
  </Tab>
</Tabs>
