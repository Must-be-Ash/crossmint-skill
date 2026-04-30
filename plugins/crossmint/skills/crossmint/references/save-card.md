# Save a Card

> Tokenize a user's card via Crossmint's PCI-compliant UI so it can later be enrolled for agentic use.

## Introduction

Saving a card enables a physical card to be tokenized for agentic use and onramps. The user enters their card into a Crossmint-hosted UI, Crossmint tokenizes it in a PCI-compliant vault, and your app receives a `paymentMethodId` it can use in later flows to retrieve card details. Raw card data never reaches your servers.

Think of this like Apple Pay or a browser storing a card once so it can be used securely later — but with one important difference. **Saving a card does not authorize agents to use it.** Enrollment is a separate, explicit step covered in the next guide.

## Prerequisites

* A registered agent with a valid `agentId`. See [Register an Agent](/agents/payment-methods/cards/register-agent) if you have not done this yet.
* The user must be authenticated and you must have a JWT for them.

## Steps

<Steps>
  <Step title="Install the SDK">
    <CodeGroup>
      ```bash npm theme={null}
      npm install @crossmint/client-sdk-react-ui
      ```

      ```bash yarn theme={null}
      yarn add @crossmint/client-sdk-react-ui
      ```

      ```bash pnpm theme={null}
      pnpm add @crossmint/client-sdk-react-ui
      ```

      ```bash bun theme={null}
      bun add @crossmint/client-sdk-react-ui
      ```
    </CodeGroup>
  </Step>

  <Step title="Wrap your app with the Crossmint provider">
    Set up `CrossmintProvider` at the root of your app. This makes the Crossmint SDK available to all child components.

    ```tsx theme={null}
    "use client";
    import { CrossmintProvider } from "@crossmint/client-sdk-react-ui";

    function App() {
        return (
            <CrossmintProvider apiKey={process.env.NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY}>
                {/* Your app */}
            </CrossmintProvider>
        );
    }
    ```
  </Step>

  <Step title="Add the card collection component">
    Place this component on a page where the user manages their payment methods, or in an ephemeral UI dedicated to saving cards.

    The `CrossmintPaymentMethodManagement` component handles all PCI compliance concerns. Card data is collected directly by Crossmint and never passes through your servers — this is why the UI must be rendered inside your app rather than called from your backend.

    <Note>
      In staging, use the test card number **4242 4242 4242 4242** with any future expiration date and any three-digit CVC. For additional scenarios, see [Testing All Flows](#testing-all-flows).
    </Note>

    ```tsx theme={null}
    import { CrossmintPaymentMethodManagement } from "@crossmint/client-sdk-react-ui";

    function PaymentMethodsPage({ jwt }: { jwt: string }) {
        // jwt comes from your own auth provider (for example Stytch, Auth0, Dynamic)

        const handlePaymentMethodSelected = (paymentMethod: { paymentMethodId: string }) => {
            // paymentMethod.paymentMethodId represents the saved card.
            // Persist it so you can enroll the card and issue virtual cards later.
            console.log("Card saved:", paymentMethod.paymentMethodId);
        };

        return (
            <div>
                <h2>Payment Methods</h2>
                <p>Save a card so your agent can request payments on your behalf.</p>
                <CrossmintPaymentMethodManagement
                    jwt={jwt}
                    onPaymentMethodSelected={handlePaymentMethodSelected}
                />
            </div>
        );
    }
    ```
  </Step>

  <Step title="Store the payment method ID">
    When the user saves a card, the `onPaymentMethodSelected` callback returns a `paymentMethodId`. Persist this ID in your backend associated with the user, apply strict access controls, and avoid exposing it in client-side storage or logs.

    The ID cannot reveal the original card number, but it can be used to initiate payment-related operations, including enrollment and virtual card issuance.
  </Step>
</Steps>

## Testing All Flows

In staging, the test card number determines how downstream flows behave — success, card-not-eligible, issuer decline, OTP challenges, and so on. Use these cards to exercise every branch of your integration without needing live cards or real issuers.

### Visa

| Card                  | Scenario                                              |
| --------------------- | ----------------------------------------------------- |
| `4242 4242 4242 4242` | Happy path — auto-approved, no passkey required       |
| `4000 0000 0000 0002` | Standard flow — OTP verification and passkey creation |
| `4000 0566 5566 5556` | Completes enrollment without passkey creation         |
| `4539 0978 8716 3333` | Card not eligible for agentic enrollment              |
| `4929 5442 4031 8920` | Declined by issuer during enrollment                  |
| `4000 0000 0000 3063` | `PROVIDER_ENROLLMENT_FAILED` — retryable              |
| `4000 0000 0000 3071` | Token provisioning failure — retryable                |
| `4330 2512 0750 6660` | `CARD_REJECTED` during network verification           |
| `4929 9803 9556 7582` | OTP submission always returns `INVALID_OTP`           |
| `4916 7252 9792 5395` | OTP submission returns `MAX_ATTEMPTS_EXCEEDED`        |

Use any future expiration date and any three-digit CVC.

## What Is Next

The `paymentMethodId` represents a saved card, but not yet a card that an agent can use. Before issuing any virtual cards, enroll the card for agentic payments.

Continue to [Enroll a Card](/agents/payment-methods/cards/enroll-card) to authorize this saved card for agent use through a one-time passkey verification step.
