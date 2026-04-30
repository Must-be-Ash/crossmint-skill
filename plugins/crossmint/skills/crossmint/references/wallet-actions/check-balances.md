# Check Balances

> Retrieve and manage wallet balances using Crossmint's APIs

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/wallets/v0/guides/check-balances) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

<Tabs>
  <Tab title="Token Balances">
    ## Prerequisites

    * Ensure you have a wallet created.
    * **API Key**: Ensure you have an API key with the scopes: `wallets.read` and `wallets:balance.read`.

    ## Retrieving Wallet Balances

    <Tabs>
      <Tab title="React">
        ```typescript theme={null}
        import { useWallet } from '@crossmint/client-sdk-react-ui';

        const { wallet } = useWallet();

        const { nativeToken, usdc, tokens } = await wallet.balances(["usdc"]);
        ```

        See the [React SDK reference](/sdk-reference/wallets/react/hooks#wallet-methods) for more details.
      </Tab>

      <Tab title="Node.js">
        ```typescript theme={null}
        import { CrossmintWallets, createCrossmint } from "@crossmint/wallets-sdk";

        const crossmint = createCrossmint({
            apiKey: "<your-server-api-key>",
        });

        const crossmintWallets = CrossmintWallets.from(crossmint);

        const wallet = await crossmintWallets.getWallet(
            "<wallet-address>",
            { chain: "base-sepolia" }
        );

        const { nativeToken, usdc, tokens } = await wallet.balances(["usdc"]);
        ```

        See the [SDK reference](/sdk-reference/wallets/typescript/classes/Wallet#balances) for all parameters and return types.
      </Tab>

      <Tab title="React Native">
        ```typescript theme={null}
        import { useWallet } from '@crossmint/client-sdk-react-native-ui';

        const { wallet } = useWallet();

        const { nativeToken, usdc, tokens } = await wallet.balances(["usdc"]);
        ```

        See the [React Native SDK reference](/sdk-reference/wallets/react-native/hooks#wallet-methods) for more details.
      </Tab>

      <Tab title="Flutter">
        ```dart theme={null}
        import 'package:crossmint_flutter/crossmint_flutter_ui.dart';

        final controller = CrossmintWalletContext.of(context).requireWalletController;
        final wallet = controller.createEvmWallet();

        final balances = await wallet.balances(tokens: <String>['usdc']);
        print('USDC: ${balances.usdc.amount}');
        print('Native: ${balances.nativeToken.amount}');
        ```

        Swap `createEvmWallet` for `createSolanaWallet` or `createStellarWallet` on
        the matching chain. See the
        [Flutter SDK reference](/sdk-reference/wallets/flutter/controllers#wallet-methods)
        for more details.
      </Tab>

      <Tab title="Swift">
        ```swift theme={null}
        import CrossmintClient
        import Wallet

        let sdk = CrossmintSDK.shared

        let wallet = try await sdk.crossmintWallets.getWallet(
            chain: .baseSepolia
        )

        let balances = try await wallet.balances(["usdc"])
        ```

        ### Parameters

        <ResponseField name="tokens" type="string[]">
          The tokens to get the balances for. This can be a token symbol or a token address.
        </ResponseField>

        ### Returns

        <ResponseField name="balances" type="Balances">
          The balances of the wallet.

          <Expandable title="properties">
            <ResponseField name="nativeToken" type="TokenBalance">
              The native token balance.

              <Snippet file="token-balance-properties.mdx" />
            </ResponseField>

            <ResponseField name="usdc" type="TokenBalance">
              The USDC balance.

              <Snippet file="token-balance-properties.mdx" />
            </ResponseField>

            <ResponseField name="tokens" type="TokenBalance[]">
              The tokens balances.

              <Snippet file="token-balance-properties.mdx" />
            </ResponseField>
          </Expandable>
        </ResponseField>
      </Tab>

      <Tab title="REST">
        <CodeGroup>
          ```bash cURL theme={null}
          curl --request GET \
              --url 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/balances?tokens=usdc&chains=base-sepolia' \
              --header 'X-API-KEY: <x-api-key>'
          ```

          ```js Node.js theme={null}
          const url = 'https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/balances?tokens=usdc&chains=base-sepolia';

          const options = {
              method: 'GET',
              headers: {
                  'X-API-KEY': '<x-api-key>'
              }
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

          url = "https://staging.crossmint.com/api/2025-06-09/wallets/email:user@example.com:evm/balances"

          querystring = {"tokens":"usdc","chains":"base-sepolia"}

          headers = {"X-API-KEY": "<x-api-key>"}

          response = requests.get(url, params=querystring, headers=headers)

          print(response.json())
          ```
        </CodeGroup>

        See the [API reference](/api-reference/wallets/get-wallet-balance) for more details.
      </Tab>
    </Tabs>
  </Tab>

  <Tab title="NFT Balances">
    ## Prerequisites

    * Ensure you have a wallet created.
    * **API Key**: Ensure you have an API key with the scopes: `wallets.read`, `wallets.nfts.read`.

    ## Retrieving NFTs

    <Tabs>
      <Tab title="React">
        ```typescript theme={null}
        import { useWallet } from '@crossmint/client-sdk-react-ui';

        const { wallet } = useWallet();

        const nfts = await wallet.nfts({ page: 1, perPage: 10 });
        ```

        See the [React SDK reference](/sdk-reference/wallets/react/hooks#wallet-methods) for more details.
      </Tab>

      <Tab title="Node.js">
        ```typescript theme={null}
        import { CrossmintWallets, createCrossmint } from "@crossmint/wallets-sdk";

        const crossmint = createCrossmint({
            apiKey: "<your-server-api-key>",
        });

        const crossmintWallets = CrossmintWallets.from(crossmint);

        const wallet = await crossmintWallets.getWallet(
            "<wallet-address>",
            { chain: "base-sepolia" }
        );

        const nfts = await wallet.nfts({ page: 1, perPage: 10 });
        ```

        See the [SDK reference](/sdk-reference/wallets/typescript/classes/Wallet#nfts) for all parameters and return types.
      </Tab>

      <Tab title="React Native">
        ```typescript theme={null}
        import { useWallet } from '@crossmint/client-sdk-react-native-ui';

        const { wallet } = useWallet();

        const nfts = await wallet.nfts({ page: 1, perPage: 10 });
        ```

        See the [React Native SDK reference](/sdk-reference/wallets/react-native/hooks#wallet-methods) for more details.
      </Tab>

      <Tab title="Flutter">
        ```dart theme={null}
        import 'package:crossmint_flutter/crossmint_flutter_ui.dart';

        final controller = CrossmintWalletContext.of(context).requireWalletController;
        final wallet = controller.createEvmWallet();

        final nfts = await wallet.nfts(page: 1, perPage: 10);
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

        let nfts = try await wallet.nfts(page: 1, nftsPerPage: 10)
        ```

        ### Parameters

        <ParamField path="nftsPerPage" type="number">
          The number of NFTs to return per page.
        </ParamField>

        <ParamField path="page" type="number">
          The page number to return.
        </ParamField>

        ### Returns

        <ParamField path="nfts" type="Promise<GetNftsResponse>">
          The NFTs.
        </ParamField>
      </Tab>

      <Tab title="REST">
        <CodeGroup>
          ```bash cURL theme={null}
          curl --request GET \
              --url 'https://staging.crossmint.com/api/2022-06-09/wallets/email:user@example.com:base/nfts?page=1&perPage=20' \
              --header 'X-API-KEY: <x-api-key>'
          ```

          ```js Node.js theme={null}
          const url = 'https://staging.crossmint.com/api/2022-06-09/wallets/email:user@example.com:base/nfts?page=1&perPage=20';

          const options = {
              method: 'GET',
              headers: {
                  'X-API-KEY': '<x-api-key>'
              }
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

          url = "https://staging.crossmint.com/api/2022-06-09/wallets/email:user@example.com:base/nfts"

          querystring = {"page":"1","perPage":"20"}

          headers = {"X-API-KEY": "<x-api-key>"}

          response = requests.get(url, params=querystring, headers=headers)

          print(response.json())
          ```
        </CodeGroup>

        See the [API reference](/api-reference/wallets/get-nfts-from-wallet) for more details.
      </Tab>
    </Tabs>
  </Tab>
</Tabs>
