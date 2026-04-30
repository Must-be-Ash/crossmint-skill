# Wallets — copy-pasteable recipes

> Every snippet here is lifted directly from the reference docs. Each section names the file it came from. Adapt to your framework; do not invent fields.

## Environment

```bash
NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY=ck_staging_...   # client-side, browser-safe
CROSSMINT_SERVER_SIDE_API_KEY=sk_staging_...          # server-only
CROSSMINT_SIGNER_SECRET=xmsk1_<64-hex>                # generate via the in-doc generator
```

> The signer secret authorizes the agent on every wallet it has been added to. Never commit, never expose to the client. Rotate if leaked.

---

## 1. Create a user wallet (React, client-side)

Source: `references/create-user-wallet.md`.

Wrap your app once. `createOnLogin` makes wallet creation idempotent and automatic on sign-in.

```tsx
"use client";

import {
  CrossmintAuthProvider,
  CrossmintProvider,
  CrossmintWalletProvider,
} from "@crossmint/client-sdk-react-ui";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <CrossmintProvider apiKey={process.env.NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY!}>
      <CrossmintAuthProvider loginMethods={["email", "google"]}>
        <CrossmintWalletProvider
          createOnLogin={{
            chain: "base-sepolia",                    // or "base" for production
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

Read the wallet anywhere below the provider:

```tsx
"use client";
import { useWallet } from "@crossmint/client-sdk-react-ui";

export function WalletAddress() {
  const { wallet, status } = useWallet();
  if (status !== "loaded") return <p>Creating wallet…</p>;
  return <code>{wallet?.address}</code>;
}
```

---

## 2. Create a user wallet (server-side / non-React)

Source: `references/create-user-wallet.md`.

```typescript
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({
  apiKey: process.env.CROSSMINT_SERVER_SIDE_API_KEY!,
});
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.createWallet({
  chain: "base-sepolia",
  owner: `userId:${userId}`,                         // required server-side
  signer: { type: "email", email: userEmail },
});
```

Pass the same `owner` on later `getWallet` calls to resolve the same wallet.

---

## 3. Authorize the agent as a delegated signer

Source: `references/authorize-agent.md`.

Two-step pattern — the user keeps veto power because the server prepares but does not auto-approve.

### 3a. Server action — prepare
```typescript
"use server";

import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

export async function prepareServerSigner({ walletAddress }: { walletAddress: string }) {
  const crossmint = createCrossmint({
    apiKey: process.env.CROSSMINT_SERVER_SIDE_API_KEY!,
  });
  const wallets = CrossmintWallets.from(crossmint);
  const wallet = await wallets.getWallet(walletAddress, { chain: "base-sepolia" });

  const { locator, signatureId } = await wallet.addSigner(
    { type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET! },
    { prepareOnly: true }                            // CRITICAL — without this, the user is bypassed
  );

  return { locator, signatureId };
}
```

### 3b. Client — user approves with email code
```tsx
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

After approval, verify with `wallet.signers()` — you should see an entry with `type: "server"`.

---

## 4. Spend from the agent (server-side, no user round-trip)

Source: `references/x402.md` and `references/using-the-wallet.md`.

```typescript
import { createCrossmint, CrossmintWallets } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({
  apiKey: process.env.CROSSMINT_SERVER_SIDE_API_KEY!,
});
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.getWallet(userWalletAddress, { chain: "base" });

await wallet.useSigner({
  type: "server",
  secret: process.env.CROSSMINT_SIGNER_SECRET!,
});

// Now the agent can sign transactions, call contracts, send stablecoins, etc.
// See references/using-the-wallet.md for the full surface.
```

---

## 5. Server agent wallet (no end user)

Source: `references/server-agent-wallets.md`.

When the agent acts entirely autonomously (no human owner), create a wallet whose root signer IS the server signer — no email, no passkey, no delegation step. Read the file for the exact `createWallet` shape.

---

## 6. Revoke

Source: `references/remove-agent-access.md`. Read the file before writing this code.
