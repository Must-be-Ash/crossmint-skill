# Create a Virtual Card

> Issue a scoped virtual card with spending mandates from a card.

## Introduction

A virtual card is issued as an **order intent** — a request to spend a specific amount against an enrolled payment method, scoped by one or more **mandates** (spending limits, a description, frequency and more).

The user authorizes the intent with their passkey, after which the virtual card becomes `active` and its credentials can be retrieved by the agent.

## Prerequisites

* A saved card that has been enrolled for agentic payments. See [Save a Card](/agents/payment-methods/cards/save-card) and [Enroll a Card](/agents/payment-methods/cards/enroll-card) if you have not done this yet.
* The `agentId` from [Register an Agent](/agents/payment-methods/cards/register-agent).
* The `paymentMethodId` of the enrolled card.
* An authenticated user with a JWT.

<Note>
  **Eligible Cards**

  You can currently create virtual cards only with eligible U.S.-issued Visa credit and debit cards.

  **Not supported:** non-US cards, business cards, prepaid cards, Chase cards, Fidelity cards.

  For Mastercard, AMEX, and Ramp cards, [contact us](https://www.crossmint.com/contact).
</Note>

## Steps

<Steps>
  <Step title="Create the order intent">
    Send a `POST` request to `/api/unstable/order-intents` with the agent, the card to charge, and one or more mandates defining the spending rules.

    ```typescript theme={null}
    const BASE_URL = "https://staging.crossmint.com/api/unstable";

    const response = await fetch(`${BASE_URL}/order-intents`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-API-KEY": CROSSMINT_CLIENT_API_KEY,
            Authorization: `Bearer ${jwt}`,
        },
        body: JSON.stringify({
            agentId: agentId,
            payment: { paymentMethodId: paymentMethodId },
            mandates: [
                {
                    type: "maxAmount",
                    value: "150.00",
                    details: { currency: "usd", period: "monthly" },
                },
                {
                    type: "description",
                    value: "Weekly grocery purchases",
                },
            ],
        }),
    });

    const orderIntent = await response.json();
    console.log(orderIntent.orderIntentId);
    console.log(orderIntent.phase);
    // "requires-verification" or "active"
    ```

    For the full list of supported mandate types and their fields, see the [Create Order Intent API Reference](/api-reference/agentic-commerce/order-intents/create-order-intent).

    **What to persist**

    | Data                                               | When                                                                                                                                      |
    | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
    | `orderIntentId`                                    | Always — every later operation keys off of it.                                                                                            |
    | Merchant descriptor (`name`, `url`, `countryCode`) | When the card will charge the same merchant repeatedly. You pass it on every credential fetch, so saving it once avoids re-collecting it. |
    | Card credentials                                   | Never — short-lived and merchant-scoped. Fetch fresh on each purchase.                                                                    |
  </Step>

  <Step title="Authorize the intent via passkey">
    If the order intent's `phase` is `requires-verification`, the user must authorize the spending with their passkey. Use the `OrderIntentVerification` component:

    ```tsx theme={null}
    import { OrderIntentVerification } from "@crossmint/client-sdk-react-ui";

    function AuthorizeSpending({ orderIntent }: { orderIntent: any }) {
        return (
            <OrderIntentVerification
                orderIntent={orderIntent}
                onVerificationComplete={() => {
                    console.log("Virtual card is now active");
                }}
                onVerificationError={() => {
                    console.error("Spending authorization failed");
                }}
            />
        );
    }
    ```

    This step is **passkey-only**. The user does not receive an email code — the one-time email verification was completed during enrollment, and the device is already bound.

    After `onVerificationComplete` fires, the order intent's phase changes to `active` and the virtual card is ready for credential retrieval.
  </Step>
</Steps>

An order intent moves through `requires-verification` → `active` → `expired`. For the full phase semantics, see the [Get Order Intent API Reference](/api-reference/agentic-commerce/order-intents/get-order-intent).

<Accordion title="Example Response">
  ```json theme={null}
  {
      "orderIntentId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "phase": "requires-verification",
      "payment": {
          "paymentMethodId": "pm_abc123"
      },
      "mandates": [
          {
              "type": "maxAmount",
              "value": "150.00",
              "details": { "currency": "usd", "period": "monthly" }
          },
          {
              "type": "description",
              "value": "Weekly grocery purchases"
          }
      ],
      "verificationConfig": {
          "environment": "test",
          "publicApiKey": "YOUR_PUBLIC_API_KEY",
          "agentId": "d290f1ee-6c54-4b01-90e6-d701748f0851",
          "instructionId": "instr_xyz789"
      }
  }
  ```
</Accordion>

For the full order intent API schema, see the [Create Order Intent API Reference](/api-reference/agentic-commerce/order-intents/create-order-intent).

## Common Gotchas

<AccordionGroup>
  <Accordion title="Virtual card issuance requires an enrolled card">
    If the `paymentMethodId` has not been enrolled, the order intent creation call will fail. Confirm `status: "active"` on the enrollment before creating an order intent.
  </Accordion>

  <Accordion title="Each new order intent needs a fresh passkey tap">
    Unless the response returns `phase: "active"` immediately, do not reuse a previous verification — each order intent has its own authorization.
  </Accordion>

  <Accordion title="Treat `onVerificationError` distinctly from `onVerificationComplete`">
    A denied or failed verification leaves the order intent in `requires-verification`. Do not attempt to fetch credentials until the phase is `active`.
  </Accordion>
</AccordionGroup>

## Next Steps

<CardGroup cols={2}>
  <Card title="Retrieve Virtual Card Credentials" icon="key" href="/agents/payment-methods/cards/retrieve-virtual-card">
    Fetch the card number, expiration, and CVC to complete a purchase.
  </Card>

  <Card title="Remove Cards" icon="trash" href="/agents/payment-methods/cards/remove-cards">
    Remove saved cards, delete agents, or rotate a virtual card.
  </Card>
</CardGroup>
