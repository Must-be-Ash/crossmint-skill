# REST API

> Create and manage wallets from your backend using the Crossmint REST API

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/wallets/v0/quickstarts/restapi) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

In this quickstart you will learn how to create wallets, check balances, and transfer tokens from your backend using the Crossmint REST API.

<CardGroup cols={2}>
  <Snippet file="before-you-start.mdx" />

  <Card title="Wallets Quickstart" icon="github" iconType="duotone" href="https://github.com/Crossmint/wallets-quickstart">
    See a full working example.
  </Card>
</CardGroup>

## Understanding Wallet Types

Crossmint supports two types of wallets:

* **Smart Wallets**: Account abstraction wallets with configurable signers. You control who can sign transactions (external wallets, server signers, passkeys, etc.).
* **MPC Wallets**: Custodial wallets where Crossmint manages the private keys using multi-party computation. Simpler setup with no signer configuration needed. <a href="https://www.crossmint.com/contact/sales" target="_blank">Contact us</a> for access.

<Steps>
  <Step title="Create a wallet">
    <Tabs>
      <Tab title="EVM Smart Wallet (Server Signer)">
        Smart wallets on EVM chains using a server signer you control.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
              --data '{
                  "chainType": "evm",
                  "type": "smart",
                  "config": {
                      "adminSigner": {
                          "type": "server",
                          "address": "YOUR_SERVER_SIGNER_ADDRESS"
                      }
                  },
                  "owner": "email:user@example.com"
              }'
          ```

          ```javascript Node.js theme={null}
          const options = {
              method: "POST",
              headers: {
                  "X-API-KEY": "YOUR_SERVER_API_KEY",
                  "Content-Type": "application/json",
              },
              body: JSON.stringify({
                  chainType: "evm",
                  type: "smart",
                  config: {
                      adminSigner: {
                          type: "server",
                          address: "YOUR_SERVER_SIGNER_ADDRESS",
                      },
                  },
                  owner: "email:user@example.com",
              }),
          };

          fetch(
              "https://staging.crossmint.com/api/2025-06-09/wallets",
              options
          )
              .then((response) => response.json())
              .then((data) => console.log("Wallet:", data.address))
              .catch((err) => console.error(err));
          ```

          ```python Python theme={null}
          import requests

          url = "https://staging.crossmint.com/api/2025-06-09/wallets"

          payload = {
              "chainType": "evm",
              "type": "smart",
              "config": {
                  "adminSigner": {
                      "type": "server",
                      "address": "YOUR_SERVER_SIGNER_ADDRESS"
                  }
              },
              "owner": "email:user@example.com"
          }
          headers = {
              "X-API-KEY": "YOUR_SERVER_API_KEY",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)
          data = response.json()
          print(f"Wallet created: {data['address']}")
          ```
        </CodeGroup>

        <Note>
          The `address` is the blockchain address derived from your server
          signer's secret key. You must derive this yourself before calling
          the API -- the REST API never sees your secret. See the
          [server signer guide](/wallets/guides/signers/server-signer)
          for how to generate and derive this address.
        </Note>

        **Key Parameters:**

        * `chainType`: The blockchain family (`evm` for Ethereum-compatible chains)
        * `type`: Wallet type (`smart` for smart wallets)
        * `config.adminSigner`: The recovery signer for the wallet
          * `type: "server"`: A signer key you manage on your server
          * `address`: The blockchain address derived from your secret
        * `owner`: User identifier in format `email:user@example.com` (optional but recommended)

        <Accordion title="Sample Response (201 Created)">
          ```json theme={null}
          {
              "chainType": "evm",
              "type": "smart",
              "address": "0xABC1234567890DEF1234567890ABCDEF12345678",
              "owner": "email:user@example.com",
              "config": {
                  "adminSigner": {
                      "type": "server",
                      "address": "YOUR_SERVER_SIGNER_ADDRESS",
                      "locator": "server:YOUR_SERVER_SIGNER_ADDRESS"
                  }
              },
              "createdAt": "2025-12-15T10:30:00.000Z"
          }
          ```

          **Save the** `address` **field** -- you'll need it to interact with this wallet.
        </Accordion>
      </Tab>

      <Tab title="EVM Smart Wallet (External Wallet)">
        Smart wallets on EVM chains with an external wallet you control as the signer.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
              --data '{
                  "chainType": "evm",
                  "type": "smart",
                  "config": {
                      "adminSigner": {
                          "type": "external-wallet",
                          "address": "YOUR_EXTERNAL_WALLET_ADDRESS"
                      }
                  },
                  "owner": "email:user@example.com"
              }'
          ```

          ```javascript Node.js theme={null}
          const options = {
              method: "POST",
              headers: {
                  "X-API-KEY": "YOUR_SERVER_API_KEY",
                  "Content-Type": "application/json",
              },
              body: JSON.stringify({
                  chainType: "evm",
                  type: "smart",
                  config: {
                      adminSigner: {
                          type: "external-wallet",
                          address: "YOUR_EXTERNAL_WALLET_ADDRESS",
                      },
                  },
                  owner: "email:user@example.com",
              }),
          };

          fetch(
              "https://staging.crossmint.com/api/2025-06-09/wallets",
              options
          )
              .then((response) => response.json())
              .then((data) => console.log("Wallet:", data.address))
              .catch((err) => console.error(err));
          ```

          ```python Python theme={null}
          import requests

          url = "https://staging.crossmint.com/api/2025-06-09/wallets"

          payload = {
              "chainType": "evm",
              "type": "smart",
              "config": {
                  "adminSigner": {
                      "type": "external-wallet",
                      "address": "YOUR_EXTERNAL_WALLET_ADDRESS"
                  }
              },
              "owner": "email:user@example.com"
          }
          headers = {
              "X-API-KEY": "YOUR_SERVER_API_KEY",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)
          data = response.json()
          print(f"Wallet created: {data['address']}")
          ```
        </CodeGroup>

        <Accordion title="Sample Response (201 Created)">
          ```json theme={null}
          {
              "chainType": "evm",
              "type": "smart",
              "address": "0xABC1234567890DEF1234567890ABCDEF12345678",
              "owner": "email:user@example.com",
              "config": {
                  "adminSigner": {
                      "type": "external-wallet",
                      "address": "YOUR_EXTERNAL_WALLET_ADDRESS",
                      "locator": "external-wallet:YOUR_EXTERNAL_WALLET_ADDRESS"
                  }
              },
              "createdAt": "2025-12-15T10:30:00.000Z"
          }
          ```
        </Accordion>
      </Tab>

      <Tab title="Solana Smart Wallet">
        Smart wallets on Solana with configurable signers.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
              --data '{
                  "chainType": "solana",
                  "type": "smart",
                  "config": {
                      "adminSigner": {
                          "type": "external-wallet",
                          "address": "YOUR_EXTERNAL_WALLET_ADDRESS"
                      }
                  },
                  "owner": "email:user@example.com"
              }'
          ```

          ```javascript Node.js theme={null}
          const options = {
              method: "POST",
              headers: {
                  "X-API-KEY": "YOUR_SERVER_API_KEY",
                  "Content-Type": "application/json",
              },
              body: JSON.stringify({
                  chainType: "solana",
                  type: "smart",
                  config: {
                      adminSigner: {
                          type: "external-wallet",
                          address: "YOUR_EXTERNAL_WALLET_ADDRESS",
                      },
                  },
                  owner: "email:user@example.com",
              }),
          };

          fetch(
              "https://staging.crossmint.com/api/2025-06-09/wallets",
              options
          )
              .then((response) => response.json())
              .then((data) => console.log("Wallet:", data.address))
              .catch((err) => console.error(err));
          ```

          ```python Python theme={null}
          import requests

          url = "https://staging.crossmint.com/api/2025-06-09/wallets"

          payload = {
              "chainType": "solana",
              "type": "smart",
              "config": {
                  "adminSigner": {
                      "type": "external-wallet",
                      "address": "YOUR_EXTERNAL_WALLET_ADDRESS"
                  }
              },
              "owner": "email:user@example.com"
          }
          headers = {
              "X-API-KEY": "YOUR_SERVER_API_KEY",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)
          print(f"Wallet created: {response.json()['address']}")
          ```
        </CodeGroup>
      </Tab>

      <Tab title="EVM MPC Wallet">
        <Note><a href="https://www.crossmint.com/contact/sales" target="_blank">Contact us</a> for access to MPC wallets.</Note>

        Custodial wallets on EVM chains.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
              --data '{
                  "chainType": "evm",
                  "type": "mpc",
                  "owner": "email:user@example.com"
              }'
          ```

          ```javascript Node.js theme={null}
          const options = {
              method: "POST",
              headers: {
                  "X-API-KEY": "YOUR_SERVER_API_KEY",
                  "Content-Type": "application/json",
              },
              body: JSON.stringify({
                  chainType: "evm",
                  type: "mpc",
                  owner: "email:user@example.com",
              }),
          };

          fetch(
              "https://staging.crossmint.com/api/2025-06-09/wallets",
              options
          )
              .then((response) => response.json())
              .then((data) => console.log("Wallet:", data.address))
              .catch((err) => console.error(err));
          ```

          ```python Python theme={null}
          import requests

          url = "https://staging.crossmint.com/api/2025-06-09/wallets"

          payload = {
              "chainType": "evm",
              "type": "mpc",
              "owner": "email:user@example.com"
          }
          headers = {
              "X-API-KEY": "YOUR_SERVER_API_KEY",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)
          print(f"Wallet created: {response.json()['address']}")
          ```
        </CodeGroup>

        <Note>
          MPC wallets don't require a `config` section. Crossmint manages the private keys securely using multi-party computation.
        </Note>
      </Tab>

      <Tab title="Solana MPC Wallet">
        <Note><a href="https://www.crossmint.com/contact/sales" target="_blank">Contact us</a> for access to MPC wallets.</Note>

        Custodial wallets on Solana.

        <CodeGroup>
          ```bash cURL theme={null}
          curl --request POST \
              --url https://staging.crossmint.com/api/2025-06-09/wallets \
              --header 'Content-Type: application/json' \
              --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
              --data '{
                  "chainType": "solana",
                  "type": "mpc",
                  "owner": "email:user@example.com"
              }'
          ```

          ```javascript Node.js theme={null}
          const options = {
              method: "POST",
              headers: {
                  "X-API-KEY": "YOUR_SERVER_API_KEY",
                  "Content-Type": "application/json",
              },
              body: JSON.stringify({
                  chainType: "solana",
                  type: "mpc",
                  owner: "email:user@example.com",
              }),
          };

          fetch(
              "https://staging.crossmint.com/api/2025-06-09/wallets",
              options
          )
              .then((response) => response.json())
              .then((data) => console.log("Wallet:", data.address))
              .catch((err) => console.error(err));
          ```

          ```python Python theme={null}
          import requests

          url = "https://staging.crossmint.com/api/2025-06-09/wallets"

          payload = {
              "chainType": "solana",
              "type": "mpc",
              "owner": "email:user@example.com"
          }
          headers = {
              "X-API-KEY": "YOUR_SERVER_API_KEY",
              "Content-Type": "application/json"
          }

          response = requests.post(url, json=payload, headers=headers)
          print(f"Wallet created: {response.json()['address']}")
          ```
        </CodeGroup>
      </Tab>
    </Tabs>

    See the [API reference](/api-reference/wallets/create-wallet) for all available parameters.
  </Step>

  <Step title="Retrieve a wallet">
    Retrieve wallet information using a <Tooltip tip="A wallet locator is a flexible way to identify a wallet. You can use the wallet address, or a user identifier with chain type.">wallet locator</Tooltip>.

    **Wallet Locator Formats:**

    * By address: `0xABC...` or `GbA2NZ...`
    * By email: `email:user@example.com:evm:smart`
    * By user ID: `userId:507f1f77bcf86cd799439011:solana:mpc`

    <CodeGroup>
      ```bash cURL theme={null}
      curl --request GET \
          --url https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm:smart \
          --header 'X-API-KEY: YOUR_SERVER_API_KEY'
      ```

      ```javascript Node.js theme={null}
      const walletLocator = "email:user@example.com:evm:smart";
      const options = {
          method: "GET",
          headers: { "X-API-KEY": "YOUR_SERVER_API_KEY" },
      };

      fetch(
          `https://staging.crossmint.com/api/2025-06-09/wallets/${walletLocator}`,
          options
      )
          .then((response) => response.json())
          .then((data) => {
              console.log("Wallet address:", data.address);
              console.log("Owner:", data.owner);
          })
          .catch((err) => console.error(err));
      ```

      ```python Python theme={null}
      import requests

      wallet_locator = "email:user@example.com:evm:smart"
      url = f"https://staging.crossmint.com/api/2025-06-09/wallets/{wallet_locator}"

      headers = {"X-API-KEY": "YOUR_SERVER_API_KEY"}

      response = requests.get(url, headers=headers)
      data = response.json()

      print(f"Wallet address: {data['address']}")
      print(f"Owner: {data['owner']}")
      ```
    </CodeGroup>

    <Accordion title="Sample Response (200 OK)">
      ```json theme={null}
      {
          "chainType": "evm",
          "type": "smart",
          "address": "0xABC1234567890DEF1234567890ABCDEF12345678",
          "owner": "email:user@example.com",
          "config": {
              "adminSigner": {
                  "type": "server",
                  "address": "YOUR_SERVER_SIGNER_ADDRESS",
                  "locator": "server:YOUR_SERVER_SIGNER_ADDRESS"
              }
          },
          "createdAt": "2025-12-15T10:30:00.000Z"
      }
      ```
    </Accordion>

    <Accordion title="More Wallet Locator Examples">
      * `0x1234567890123456789012345678901234567890` - Direct address
      * `email:user@example.com:evm:smart` - Email + wallet type
      * `userId:507f1f77bcf86cd799439011:solana:mpc` - User ID + wallet type
      * `phoneNumber:+12125551234:evm:smart` - Phone + wallet type
      * `twitter:johndoe:evm:smart` or `x:@johndoe:evm:smart` - Twitter/X + wallet type
    </Accordion>
  </Step>

  <Step title="Check wallet balance">
    Check token balances for a wallet. You can query multiple tokens at once by providing a comma-separated list.

    <CodeGroup>
      ```bash cURL theme={null}
      curl --request GET \
          --url 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/balances?tokens=usdc,eth' \
          --header 'X-API-KEY: YOUR_SERVER_API_KEY'
      ```

      ```javascript Node.js theme={null}
      const walletLocator = "email:user@example.com:evm";
      const tokens = "usdc,eth";
      const url =
          `https://staging.crossmint.com/api/2025-06-09/wallets/` +
          `${walletLocator}/balances?tokens=${tokens}`;

      const options = {
          method: "GET",
          headers: { "X-API-KEY": "YOUR_SERVER_API_KEY" },
      };

      fetch(url, options)
          .then((response) => response.json())
          .then((data) => {
              console.log("Native token:", data.nativeToken);
              console.log("Token balances:", data.tokens);
          })
          .catch((err) => console.error(err));
      ```

      ```python Python theme={null}
      import requests

      wallet_locator = "email:user@example.com:evm"
      url = f"https://staging.crossmint.com/api/2025-06-09/wallets/{wallet_locator}/balances"

      params = {"tokens": "usdc,eth"}
      headers = {"X-API-KEY": "YOUR_SERVER_API_KEY"}

      response = requests.get(url, params=params, headers=headers)
      data = response.json()

      print(f"Native token: {data['nativeToken']}")
      print(f"Token balances: {data['tokens']}")
      ```
    </CodeGroup>

    **Query Parameters:**

    * `tokens` (required): Comma-separated list of token symbols (e.g., `usdc,eth,usdxm`)
    * `chains` (optional): Filter by specific chains when using multi-chain wallets

    <Accordion title="Sample Response (200 OK)">
      ```json theme={null}
      {
          "nativeToken": {
              "symbol": "ETH",
              "decimals": 18,
              "balance": "1500000000000000000",
              "balanceUSD": "4500.00"
          },
          "tokens": [
              {
                  "symbol": "USDC",
                  "decimals": 6,
                  "balance": "1000000000",
                  "balanceUSD": "1000.00",
                  "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
              }
          ]
      }
      ```

      Balances are returned as strings in the token's smallest unit (wei for ETH, lamports for SOL, etc.).
    </Accordion>
  </Step>

  <Step title="Transfer tokens">
    Send tokens from a wallet to a recipient. Smart wallets handle gas fees automatically through Crossmint's paymaster.

    **Token Locator Format**: `{chain}:{symbol}` or `{chain}:{contractAddress}` (e.g., `base-sepolia:eth`, `polygon:usdc`, `base-sepolia:0x123...`)

    <CodeGroup>
      ```bash cURL theme={null}
      curl --request POST \
          --url 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/tokens/base-sepolia:eth/transfers' \
          --header 'Content-Type: application/json' \
          --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
          --data '{
              "recipient": "RECIPIENT_ADDRESS",
              "amount": "0.001"
          }'
      ```

      ```javascript Node.js theme={null}
      const walletLocator = "email:user@example.com:evm";
      const tokenLocator = "base-sepolia:eth";
      const url =
          `https://staging.crossmint.com/api/2025-06-09/wallets/` +
          `${walletLocator}/tokens/${tokenLocator}/transfers`;

      const options = {
          method: "POST",
          headers: {
              "X-API-KEY": "YOUR_SERVER_API_KEY",
              "Content-Type": "application/json",
          },
          body: JSON.stringify({
              recipient: "RECIPIENT_ADDRESS",
              amount: "0.001",
          }),
      };

      fetch(url, options)
          .then((response) => response.json())
          .then((data) => {
              console.log("Transaction ID:", data.id);
              console.log("Status:", data.status);
          })
          .catch((err) => console.error(err));
      ```

      ```python Python theme={null}
      import requests

      wallet_locator = "email:user@example.com:evm"
      token_locator = "base-sepolia:eth"
      base = "https://staging.crossmint.com/api/2025-06-09"
      url = f"{base}/wallets/{wallet_locator}/tokens/{token_locator}/transfers"

      payload = {
          "recipient": "RECIPIENT_ADDRESS",
          "amount": "0.001"
      }
      headers = {
          "X-API-KEY": "YOUR_SERVER_API_KEY",
          "Content-Type": "application/json"
      }

      response = requests.post(url, json=payload, headers=headers)
      data = response.json()

      print(f"Transaction ID: {data['id']}")
      print(f"Status: {data['status']}")
      ```
    </CodeGroup>

    **Request Parameters:**

    * `recipient` (required): Destination address or locator (e.g., `0x...`, `email:user@example.com`)
    * `amount` (required): Amount to transfer in decimal format (e.g., `"0.001"` for 0.001 ETH)

    <Accordion title="Sample Response (201 Created)">
      ```json theme={null}
      {
          "id": "cm47h2m8e0003vn0zf8yz1234",
          "chainType": "evm",
          "walletType": "smart",
          "status": "pending",
          "params": {
              "calls": [],
              "chain": "base-sepolia",
              "signer": {
                  "type": "evm-keypair",
                  "address": "0x..."
              }
          },
          "onChain": {
              "userOperationHash": "0x...",
              "txId": null
          },
          "sendParams": {
              "token": "base-sepolia:eth",
              "recipient": "RECIPIENT_ADDRESS",
              "amount": "0.001"
          },
          "createdAt": "2025-12-15T10:35:00.000Z"
      }
      ```

      **Transaction Status Values:**

      * `awaiting-approval` - Transaction created, waiting for signer approval
      * `pending` - Transaction submitted to the blockchain
      * `success` - Transaction confirmed onchain
      * `failed` - Transaction failed

      Poll the transaction status using the transaction ID, or set up [webhooks](/wallets/guides/webhooks) for real-time updates.
    </Accordion>

    <Accordion title="Common Token Locators">
      **EVM Chains:**

      * `base-sepolia:eth` - ETH on Base Sepolia testnet
      * `base-sepolia:usdc` - USDC on Base Sepolia
      * `polygon:usdc` - USDC on Polygon mainnet
      * `ethereum:usdt` - USDT on Ethereum mainnet

      **Solana:**

      * `solana:sol` - Native SOL token
      * `solana:usdc` - USDC on Solana

      For contract tokens, use the contract address: `base-sepolia:0x123...`
    </Accordion>
  </Step>
</Steps>

### Using Idempotency Keys

Prevent duplicate wallet creation by using idempotency keys:

```bash theme={null}
curl --request POST \
    --url https://staging.crossmint.com/api/2025-06-09/wallets \
    --header 'Content-Type: application/json' \
    --header 'X-API-KEY: YOUR_SERVER_API_KEY' \
    --header 'x-idempotency-key: unique-operation-id-123' \
    --data '{
        "chainType": "evm",
        "type": "smart",
        "config": {
            "adminSigner": {
                "type": "server",
                "address": "YOUR_SERVER_SIGNER_ADDRESS"
            }
        },
        "owner": "email:user@example.com"
    }'
```

If you retry with the same idempotency key, you'll receive the same wallet without creating a duplicate.

## Launching in Production

Ready to go live? Here's what you need to do:

1. Create a production account at <a href="https://www.crossmint.com/console" target="_blank">[www.crossmint.com/console](http://www.crossmint.com/console)</a>
2. Create a production API key with the required scopes:
   * `wallets.create`, `wallets.read`, `wallets:balance.read`, `wallets:transactions.create`
3. Update your API endpoint from `staging.crossmint.com` to `www.crossmint.com`
4. Update your API key in your code to use the production key

<Warning>
  Never expose your server-side API keys in client-side code or public repositories. Store them securely in environment variables or a secrets manager.
</Warning>

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
