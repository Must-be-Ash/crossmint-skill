# Hooks

> React hooks for React SDK reference for Crossmint wallets

<Note>
  **This page has been updated for Wallets SDK V1.** If you are using the previous version,
  see the [previous version of this page](/sdk-reference/wallets/v0/react/hooks) or the [V1 migration guide](/wallets/guides/migrate-to-v1).
</Note>

***

## useWallet()

### Returns

<ResponseField name="wallet" type="Wallet | undefined">
  The current wallet instance, or undefined if no wallet is loaded.
</ResponseField>

<ResponseField name="status" type="WalletStatus">
  Current wallet status. Options: `not-loaded` | `in-progress` | `loaded` | `error`.
</ResponseField>

<ResponseField name="getWallet" type="(props: Pick<ClientSideWalletArgsFor<Chain>, &#x22;chain&#x22; | &#x22;alias&#x22;>) => Promise<Wallet | undefined>">
  Retrieves an existing wallet. Returns undefined if no wallet is found.

  <Expandable title="parameters">
    <ResponseField name="chain" type="Chain">
      The blockchain of the wallet to retrieve (e.g. "base-sepolia").
    </ResponseField>

    <ResponseField name="alias" type="string">
      Optional wallet alias to look up.
    </ResponseField>
  </Expandable>
</ResponseField>

<ResponseField name="createWallet" type="(props: ClientSideWalletCreateArgs<Chain>) => Promise<Wallet | undefined>">
  Creates a new wallet with the specified chain and recovery signer.

  <Expandable title="parameters">
    <ResponseField name="chain" type="Chain">
      The blockchain to create the wallet on (e.g. "base-sepolia").
    </ResponseField>

    <ResponseField name="recovery" type="SignerConfigForChain">
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

<ResponseField name="createDeviceSigner" type="() => Promise<DeviceSignerDescriptor> | undefined">
  Creates a device signer using the provider's key storage. Returns undefined if device signing is not available.
</ResponseField>

<ResponseField name="createPasskeySigner" type="(passkeyName: string) => Promise<RegisterSignerPasskeyParams>">
  Creates a passkey signer via WebAuthn biometric prompt. EVM only.
</ResponseField>

### Usage

```tsx theme={null}
import { useWallet } from "@crossmint/client-sdk-react-ui";

function WalletActions() {
    const { wallet, status } = useWallet();

    if (status === "in-progress") return <p>Loading wallet...</p>;
    if (!wallet) return <p>No wallet</p>;

    const handleSend = async () => {
        const tx = await wallet.send("0x...", "usdc", "10");
        console.log("Transaction:", tx.explorerLink);
    };

    const handleBalances = async () => {
        const balances = await wallet.balances();
        console.log("USDC:", balances.usdc.amount);
        console.log("Native:", balances.nativeToken.amount);
    };

    return (
        <div>
            <p>Wallet: {wallet.address}</p>
            <button onClick={handleBalances}>Check Balances</button>
            <button onClick={handleSend}>Send USDC</button>
        </div>
    );
}
```

***

## Wallet Methods

The `wallet` instance returned by `useWallet()` provides methods for token transfers, balances, signing, and more.

Since the React SDK wraps the Wallets SDK, see the **[Wallets SDK Reference](/sdk-reference/wallets/typescript/classes/Wallet)** for complete documentation.

| Method                                                                                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`wallet.addSigner()`](/sdk-reference/wallets/typescript/classes/Wallet#addsigner)                   | Add a signer to the wallet. Always uses the recovery signer internally to approve the registration. If the signer being added is the current operational signer, it will be reassembled with the new locator. Otherwise, the original signer is restored after the operation.                                                                                                                                                                                                                                                                                                                                                                   |
| [`wallet.balances()`](/sdk-reference/wallets/typescript/classes/Wallet#balances)                     | Get the wallet balances - always includes USDC and native token (ETH/SOL)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| [`wallet.needsRecovery()`](/sdk-reference/wallets/typescript/classes/Wallet#needsrecovery)           | Whether the wallet needs recovery (signer registration) before the next transaction.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| [`wallet.nfts()`](/sdk-reference/wallets/typescript/classes/Wallet#nfts)                             | Get the wallet NFTs                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| [`wallet.recover()`](/sdk-reference/wallets/typescript/classes/Wallet#recover)                       | Register a device signer with the wallet using the recovery signer. Generates a new device key and registers it on-chain. Returns early if the device signer's locator is already approved on-chain.                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| [`wallet.send()`](/sdk-reference/wallets/typescript/classes/Wallet#send)                             | Send a token to a wallet or user locator                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| [`wallet.signerIsRegistered()`](/sdk-reference/wallets/typescript/classes/Wallet#signerisregistered) | Check if a signer is registered in this wallet.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [`wallet.signers()`](/sdk-reference/wallets/typescript/classes/Wallet#signers)                       | List the signers for this wallet. Returns full signer objects with status. For EVM wallets, only signers with an approval (pending or completed) for the wallet's chain are included.                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| [`wallet.stagingFund()`](/sdk-reference/wallets/typescript/classes/Wallet#stagingfund)               | Funds the wallet with Crossmint's stablecoin (USDXM).  **Note:** This method is only available in staging environments and exclusively supports USDXM tokens. It cannot be used in production environments.                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| [`wallet.transaction()`](/sdk-reference/wallets/typescript/classes/Wallet#transaction)               | Get a transaction by id                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| [`wallet.transactions()`](/sdk-reference/wallets/typescript/classes/Wallet#transactions)             | Get the wallet transactions                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| [`wallet.transfers()`](/sdk-reference/wallets/typescript/classes/Wallet#transfers)                   | Get the wallet transfers                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| [`wallet.useSigner()`](/sdk-reference/wallets/typescript/classes/Wallet#usesigner)                   | Set the active signer for this wallet. Accepts a signer config object. The locator is inferred internally. Works for both registered signers and the recovery signer.  For passkey signers: if no `id` is provided, the wallet will auto-select the passkey if exactly one passkey signer is registered. If multiple passkeys exist, an `id` must be specified.  For device signers: if no device key is found locally, the signer will be created automatically during the next transaction (via recovery).  For external-wallet signers: the config object must include an onSign callback (applies to both registered and recovery signers). |

**Chain-specific:**

* [`EVMWallet`](/sdk-reference/wallets/typescript/classes/EVMWallet) — `getViemClient()`, `sendTransaction()`, `signMessage()`, `signTypedData()`
* [`SolanaWallet`](/sdk-reference/wallets/typescript/classes/SolanaWallet) — `sendTransaction()`
* [`StellarWallet`](/sdk-reference/wallets/typescript/classes/StellarWallet) — `sendTransaction()`
