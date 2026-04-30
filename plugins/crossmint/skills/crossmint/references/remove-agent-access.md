# Remove Agent Access

> Revoke an agent signer from a user's wallet.

## Introduction

This page covers how to remove an agent's access to a user's wallet by revoking its server signer. The user authorizes the removal with their recovery signer, and the signer is immediately removed from the wallet's signer set.

## Prerequisites

* A user wallet with at least one server signer authorized. See [Authorize the Agent](/agents/payment-methods/stablecoin-wallets/authorize-agent) if you have not done this yet.
* The `locator` returned by `wallet.addSigner(...)` (or the signer address — both work as locators).
* The user's recovery signer (for example, their email signer) — revocation must be authorized by the user, not by the agent itself.

## Revoke an agent signer

Use this when the user wants to cut off a specific agent from a specific wallet. The user authorizes removal with their recovery signer (one-time email code), and the server signer is immediately removed from the wallet's signer set. Any in-flight signature requests against that signer fail.

```typescript theme={null}
"use client";

import { useWallet, useCrossmintAuth } from "@crossmint/client-sdk-react-ui";

export function RevokeAgent({ locator }: { locator: string }) {
    const { wallet } = useWallet();
    const { user } = useCrossmintAuth();

    const handleRevoke = async () => {
        if (!wallet || !user?.email) return;

        // Activate the user's recovery signer — only the user can authorize removal
        await wallet.useSigner({ type: "email", email: user.email });
        await wallet.removeSigner({ locator });
    };

    return <button onClick={handleRevoke}>Revoke agent</button>;
}
```

<Note>
  Revocation is per-wallet. If the same server secret has been authorized on multiple wallets — for example because you use a single backend signer for many users — removing it from one wallet does **not** affect the others.
</Note>

## Common Gotchas

<AccordionGroup>
  <Accordion title="Only the recovery signer can remove an agent">
    Calls to `wallet.removeSigner` must be made with the user's recovery signer active (e.g. `wallet.useSigner({ type: "email", email: user.email })`). If the server signer is active when you call remove, the request fails — by design, an agent cannot revoke itself.
  </Accordion>

  <Accordion title="Per-wallet `locator`s, not per-secret">
    The same secret produces a different `locator` on each wallet it is authorized on. Persist the `locator` returned by `addSigner` against the wallet address so revocation can target the right entry.
  </Accordion>
</AccordionGroup>

## Next Steps

<CardGroup cols={2}>
  <Card title="Authorize the Agent" icon="user-check" href="/agents/payment-methods/stablecoin-wallets/authorize-agent">
    Re-authorize an agent on the wallet after revocation.
  </Card>

  <Card title="Server Signer Deep Dive" icon="server" href="/wallets/guides/signers/server-signer">
    Full reference for the server signer.
  </Card>
</CardGroup>
