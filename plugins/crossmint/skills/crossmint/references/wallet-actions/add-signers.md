# Wallet Action: Add Operational Signers

> Source: `https://docs.crossmint.com/wallets/guides/signers/add-signers`. Adds an additional signer to an existing wallet (operational signer, distinct from the recovery signer set at creation).

## Recovery vs Operational signers

| | Recovery signer | Operational (delegated) signer |
|---|---|---|
| Set at | Wallet creation (`recovery: {...}`) | Any time after creation, via `addSigner` |
| Removable | No (root of trust) | Yes |
| Approves high-privilege ops? | Yes (e.g. adding new signers) | No |
| SDK field | `recovery` on `createWallet` | `signers: []` on `createWallet`, or `wallet.addSigner(...)` |
| REST field | `config.adminSigner` | `config.delegatedSigners` |

## How `addSigner` works under the hood

1. Submits the new signer registration request.
2. Temporarily activates the recovery signer to approve the operation.
3. Restores the previously active signer afterward.

For client-side wallets with email/phone recovery, the user gets an OTP. Server-signer recovery approves automatically.

## Operational signer types

| Type | Addable via `addSigner()`? | Chains | Required fields |
|---|---|---|---|
| `passkey` | Yes | EVM | WebAuthn id + name + publicKey (x, y) |
| `external-wallet` | Yes | EVM, Solana, Stellar | `address` |
| `server` | Yes | EVM, Solana, Stellar | `secret` |
| `device` | Auto (during cross-device recovery) | EVM, Stellar | n/a |

## Recovery-only signer types (set at create, NOT addable)

| Type | Chains | Notes |
|---|---|---|
| `email` | All | OTP-based approval |
| `phone` | All | OTP-based approval |

> **Email and phone signers cannot be added via `addSigner()`.** They're only configured at wallet creation as recovery signers.

## SDK — add a server signer

```typescript
const { locator, signatureId } = await wallet.addSigner({
  type:   "server",
  secret: process.env.NEW_SIGNER_SECRET,
});
```

For client-side wallets where the user must approve, pass `prepareOnly: true` from a server action:

```typescript
"use server";
const { locator, signatureId } = await wallet.addSigner(
  { type: "server", secret: process.env.NEW_SIGNER_SECRET },
  { prepareOnly: true }            // CRITICAL — without this the server signs its own approval
);
return { locator, signatureId };
```

Then on the client:

```tsx
const { signatureId } = await prepareServerSigner({ walletAddress: wallet.address });
await wallet.useSigner({ type: "email", email: user.email });
await wallet.approve({ signatureId });   // triggers the user's email OTP
```

This is the same flow `references/authorize-agent.md` uses for the agents-payments cards stack.

## SDK — add a passkey signer (EVM)
```typescript
await wallet.addSigner({
  type: "passkey",
  id: "<credential-id>",
  name: "My Passkey",
  publicKey: { x: <decimal>, y: <decimal> }
});
```

## SDK — add an external-wallet signer
```typescript
await wallet.addSigner({
  type: "external-wallet",
  address: "0x...",      // EVM
  // or address: base58 for Solana / Stellar
});
```

## List existing signers

```typescript
const signers = await wallet.signers();
// → array of { type, address, locator, role: "recovery" | "operational" }
```

## Common gotchas

- **Always `prepareOnly: true` from a server action when the recovery signer is server-side and the approval should come from the user.** Without it the server signer auto-approves its own request and the user is bypassed.
- **The new operational signer cannot sign yet** until the recovery approval lands. Check the status by calling `wallet.signers()`.
- **You cannot replace the recovery signer.** Add operational signers to delegate; create a new wallet if you need a different root.
