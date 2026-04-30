# Providers

> React context providers for React SDK reference for Crossmint wallets

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/sdk-reference/wallets/v0/react/providers) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

1. `CrossmintProvider` — SDK initialization (required for all Crossmint features)
2. `CrossmintWalletProvider` — Wallet creation and management

***

## CrossmintProvider

### Props

<ResponseField name="apiKey" type="string" required>
  Your Crossmint client-side API key.
</ResponseField>

<ResponseField name="appId" type="string">
  Application identifier, sent as `x-app-identifier` header.
</ResponseField>

<ResponseField name="consoleLogLevel" type="ConsoleLogLevel">
  Minimum log level for console output (or "silent" to suppress all output). Logs below this level will not be written to the console. Set to "silent" to completely suppress console output. Defaults to "debug" (all logs shown) for backward compatibility.
</ResponseField>

<ResponseField name="extensionId" type="string">
  Extension identifier, sent as `x-extension-id` header.
</ResponseField>

<ResponseField name="jwt" type="string">
  JWT token for authentication.
</ResponseField>

<ResponseField name="overrideBaseUrl" type="string">
  Override the base API URL.
</ResponseField>

### Usage

```tsx theme={null}
import { CrossmintProvider } from "@crossmint/client-sdk-react-ui";

function App() {
    return (
        <CrossmintProvider apiKey="YOUR_CLIENT_API_KEY">
            {/* Your app content */}
        </CrossmintProvider>
    );
}
```

***

## CrossmintWalletProvider

### Props

<ResponseField name="appearance" type="UIConfig">
  Appearance configuration for wallet UI components.
</ResponseField>

<ResponseField name="callbacks" type="{ onTransactionStart?: () => Promise<void>; onWalletCreationStart?: () => Promise<void> }">
  Lifecycle callbacks for wallet creation and transaction events.
</ResponseField>

<ResponseField name="createOnLogin" type="CreateOnLogin">
  Configuration for automatic wallet creation on login.

  <Expandable title="properties">
    <ResponseField name="chain" type="Chain" required>
      The blockchain to create the wallet on (e.g. "base-sepolia").
    </ResponseField>

    <ResponseField name="recovery" type="SignerConfigForChain" required>
      The recovery signer configuration (e.g. `{ type: "email" }`). Used for wallet recovery and adding new signers.
    </ResponseField>

    <ResponseField name="signers" type="SignerConfigForChain[]">
      Optional array of operational signers. Defaults to a device signer if omitted (e.g. `[{ type: "device" }]`).
    </ResponseField>

    <ResponseField name="alias" type="string">
      Optional wallet alias.
    </ResponseField>

    <ResponseField name="plugins" type="WalletPlugin[]">
      Optional array of wallet plugins.
    </ResponseField>
  </Expandable>
</ResponseField>

<ResponseField name="showOtpSignerPrompt" type="boolean">
  When true (default), built-in OTP signer UI prompts are shown during signing flows. When false, signing flows must be handled manually via the useWalletOtpSigner hook. Default: true.
</ResponseField>

<ResponseField name="showPasskeyHelpers" type="boolean">
  Whether to show passkey helper UI. Default: true.
</ResponseField>

### Usage

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
                {/* Your app content */}
            </CrossmintWalletProvider>
        </CrossmintProvider>
    );
}
```

> **Note:** CrossmintWalletProvider must be nested inside CrossmintProvider.
