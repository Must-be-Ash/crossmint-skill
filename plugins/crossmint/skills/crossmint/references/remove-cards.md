# Remove Cards

> Remove saved cards, delete agents, and rotate virtual cards.

## Introduction

This page covers the independent lifecycle operations for the cards flow. Pick the section that matches what you need to do — each operation is self-contained.

| If you need to…                                                | See                                             |
| -------------------------------------------------------------- | ----------------------------------------------- |
| Stop a saved card from being used for any future virtual cards | [Remove a saved card](#remove-a-saved-card)     |
| Cut off an agent's ability to issue new virtual cards          | [Delete an agent](#delete-an-agent)             |
| Replace a virtual card whose credentials may be compromised    | [Rotate a virtual card](#rotate-a-virtual-card) |

## Prerequisites

* An authenticated user with a valid JWT.
* The ID of the resource you want to modify (`paymentMethodId` for a card, `agentId` for an agent).

## Remove a Saved Card

Send a `DELETE` request with the `paymentMethodId`. The card can no longer be used to issue new virtual cards.

```typescript theme={null}
const BASE_URL = "https://staging.crossmint.com/api/unstable";

async function removePaymentMethod(jwt: string, paymentMethodId: string) {
    const response = await fetch(
        `${BASE_URL}/payment-methods/${paymentMethodId}`,
        {
            method: "DELETE",
            headers: {
                "Content-Type": "application/json",
                "X-API-KEY": CROSSMINT_CLIENT_API_KEY,
                Authorization: `Bearer ${jwt}`,
            },
        }
    );

    if (!response.ok) {
        throw new Error(`Failed to remove payment method (${response.status})`);
    }
}
```

<Note>
  Removing a saved card does **not** cancel virtual cards already issued against it. Active order intents keep working until their internal expiration is reached. To cut off an in-flight order intent immediately, delete the agent instead.
</Note>

## Delete an Agent

Send a `DELETE` request with the `agentId`. The agent loses the ability to issue new virtual cards, and any active order intents tied to it stop working.

```typescript theme={null}
const BASE_URL = "https://staging.crossmint.com/api/unstable";

async function deleteAgent(jwt: string, agentId: string) {
    const response = await fetch(
        `${BASE_URL}/agents/${agentId}`,
        {
            method: "DELETE",
            headers: {
                "Content-Type": "application/json",
                "X-API-KEY": CROSSMINT_CLIENT_API_KEY,
                Authorization: `Bearer ${jwt}`,
            },
        }
    );

    if (!response.ok) {
        throw new Error(`Failed to delete agent (${response.status})`);
    }
}
```

<Warning>
  Deletion is permanent. To restore the agent's ability to spend, register a new agent by following [Register an Agent](/agents/payment-methods/cards/register-agent).
</Warning>

## Rotate a Virtual Card

There is no explicit revoke endpoint for an individual order intent. To rotate a virtual card — for example if its credentials may have been compromised — issue a replacement and stop using the old one:

1. Create a new order intent against the same saved card with the same (or updated) mandates. See [Create a Virtual Card](/agents/payment-methods/cards/create-virtual-card).
2. Have the user authorize the new intent via passkey.
3. Stop passing the old credentials to your checkout flow. They expire automatically based on their `expiresAt` timestamp.

```typescript theme={null}
// Issue a replacement virtual card against the same payment method
const newOrderIntent = await createOrderIntent(jwt, agentId, paymentMethodId, mandates);

// If requires-verification, prompt the user for passkey authorization,
// then fetch credentials for the new card
const newCredentials = await fetchCardCredentials(jwt, newOrderIntent.orderIntentId, merchant);
```

<Note>
  To cut off an agent's access to **all** of its virtual cards immediately, [delete the agent](#delete-an-agent) instead. Individual order intents cannot be revoked on demand. For the full list of order intent phases and how `expired` is reached, see the [Get Order Intent API Reference](/api-reference/agentic-commerce/order-intents/get-order-intent).
</Note>

## Next Steps

<CardGroup cols={2}>
  <Card title="Create a Virtual Card" icon="credit-card" href="/agents/payment-methods/cards/create-virtual-card">
    Issue a new scoped virtual card with updated spending mandates.
  </Card>

  <Card title="Register an Agent" icon="robot" href="/agents/payment-methods/cards/register-agent">
    Create a new agent after deleting one.
  </Card>
</CardGroup>
