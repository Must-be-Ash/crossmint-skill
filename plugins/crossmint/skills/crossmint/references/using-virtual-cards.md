# Using Virtual Cards

> Fetch the card number, expiration, and CVC for an active virtual card.

## Introduction

Retrieving credentials is the final step in the cards flow. Once an order intent is `active`, you exchange the `orderIntentId` and a merchant descriptor for a card number, expiration, and CVC that the agent uses to complete the purchase.

Credentials are scoped to the merchant you specify, so they can only be used where the user authorized the spending.

## Prerequisites

* An order intent with `phase: "active"`. See [Create a Virtual Card](/agents/payment-methods/cards/create-virtual-card) if you have not done this yet.
* The `orderIntentId` of the active order intent.
* An authenticated user with a JWT.

## Fetch Credentials

Send a `POST` request to `/api/unstable/order-intents/{orderIntentId}/credentials` with the merchant information. The merchant details are required so that Crossmint can generate credentials scoped to that specific merchant.

```typescript theme={null}
const BASE_URL = "https://staging.crossmint.com/api/unstable";

const response = await fetch(
    `${BASE_URL}/order-intents/${orderIntentId}/credentials`,
    {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-API-KEY": CROSSMINT_API_KEY,
            Authorization: `Bearer ${jwt}`,
        },
        body: JSON.stringify({
            merchant: {
                name: "Whole Foods",
                url: "https://www.wholefoodsmarket.com",
                countryCode: "US",
            },
        }),
    }
);

const credentials = await response.json();
```

The response contains the virtual card details your agent needs to complete a purchase:

```json theme={null}
{
    "card": {
        "number": "4000056655665556",
        "expirationMonth": "12",
        "expirationYear": "2027",
        "cvc": "123"
    },
    "expiresAt": "2026-05-01T00:00:00Z"
}
```

### Merchant Fields

| Field         | Description                                                |
| ------------- | ---------------------------------------------------------- |
| `name`        | Display name of the merchant                               |
| `url`         | The merchant's website URL                                 |
| `countryCode` | Two-letter ISO country code (for example `US`, `GB`, `DE`) |

The merchant descriptor must be passed on every credential fetch — it is not stored on the order intent. For recurring spend at a fixed merchant, persist these fields alongside the `orderIntentId` when you create the virtual card. See [What to persist](/agents/payment-methods/cards/create-virtual-card#step-1) on the Create a Virtual Card page for the full guidance.

## List Virtual Cards

To see all virtual cards (order intents) for the authenticated user, send a `GET` request to the order intents endpoint:

```typescript theme={null}
const BASE_URL = "https://staging.crossmint.com/api/unstable";

const response = await fetch(`${BASE_URL}/order-intents`, {
    headers: {
        "Content-Type": "application/json",
        "X-API-KEY": CROSSMINT_API_KEY,
        Authorization: `Bearer ${jwt}`,
    },
});

const orderIntents = await response.json();
// Returns an array of order intents with their phases and mandates
```

Only order intents with `phase: "active"` can have their credentials fetched. Expired order intents return an error.

For the full credentials API schema, see the [Get Order Intent Credentials API Reference](/api-reference/agentic-commerce/order-intents/get-order-intent-credentials).

## Common Gotchas

<AccordionGroup>
  <Accordion title="Credentials are merchant-scoped">
    The `merchant` field is required on every credential request. A card fetched for one merchant will not authorize at another — if the agent needs to spend at a different merchant, issue a new order intent.
  </Accordion>

  <Accordion title="Credentials have their own `expiresAt`">
    Even within an `active` order intent, the returned card data is short-lived. Fetch credentials as close to the purchase as possible rather than caching them.
  </Accordion>

  <Accordion title="Fetching credentials before the phase is active fails">
    If the user has not yet completed the passkey authorization, wait for `onVerificationComplete` before calling this endpoint.
  </Accordion>
</AccordionGroup>

## Next Steps

<CardGroup cols={2}>
  <Card title="Remove Cards" icon="trash" href="/agents/payment-methods/cards/remove-cards">
    Remove saved cards, delete agents, or rotate a virtual card.
  </Card>

  <Card title="Cards Quickstart" icon="credit-card" href="/agents/cards-quickstart">
    Revisit how credential retrieval fits into the full cards flow.
  </Card>
</CardGroup>
