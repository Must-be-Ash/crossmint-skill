# Enroll a Card

> Authorize a saved card for agentic use with a one-time device-binding ceremony.

## Introduction

A saved card is not automatically usable by agents. Before you can issue virtual cards against it, the card must be **enrolled for agentic payments**. Enrollment is a one-time step per card that produces two things:

1. **Account verification** via a one-time code sent to the user's email.
2. **A passkey bound to the user's device**, so future virtual card authorizations only need a single passkey tap.

Once a card is enrolled, every subsequent virtual card issued from it can be authorized by the user with their passkey alone. The email step is not repeated.

## Prerequisites

* A saved card. See [Save a Card](/agents/payment-methods/cards/save-card) if you have not done this yet.
* The `paymentMethodId` of the saved card.
* An authenticated user with a JWT.

<Note>
  **Eligible Cards**

  You can currently create virtual cards only with eligible U.S.-issued Visa credit and debit cards.

  **Not supported:** non-US cards, business cards, prepaid cards, Chase cards, Fidelity cards.

  For Mastercard, AMEX, and Ramp cards, [contact us](https://www.crossmint.com/contact).
</Note>

## Steps

<Steps>
  <Step title="Check the card's current enrollment status">
    Before starting enrollment, check whether the card is already enrolled. The API returns a `status` that is always one of the following:

    | Status        | Meaning                                                                                       |
    | :------------ | :-------------------------------------------------------------------------------------------- |
    | `not_started` | Enrollment has not been started yet.                                                          |
    | `pending`     | Enrollment was started; the user still needs to complete verification (email and/or passkey). |
    | `active`      | Enrollment finished; the card is ready for agentic virtual card issuance.                     |

    ```typescript theme={null}
    const BASE_URL = "https://staging.crossmint.com/api/unstable";

    async function checkEnrollment(jwt: string, paymentMethodId: string) {
        const response = await fetch(
            `${BASE_URL}/payment-methods/${paymentMethodId}/agentic-enrollment`,
            {
                headers: {
                    "Content-Type": "application/json",
                    "X-API-KEY": CROSSMINT_CLIENT_API_KEY,
                    Authorization: `Bearer ${jwt}`,
                },
            }
        );

        return response.json();
        // { status: "active" | "pending" | "not_started", ... }
    }
    ```

    If the status is `active`, enrollment is complete and you can skip directly to [Create a Virtual Card](/agents/payment-methods/cards/create-virtual-card). If it is `pending`, reuse the existing enrollment response in the next step rather than creating a new one.
  </Step>

  <Step title="Start enrollment">
    If the card is `not_started`, send a `POST` request with the user's email to begin enrollment. The response includes an `enrollmentId` and a `verificationConfig` that the verification component uses to run the passkey ceremony.

    ```typescript theme={null}
    async function startEnrollment(
        jwt: string,
        paymentMethodId: string,
        email: string
    ) {
        const response = await fetch(
            `${BASE_URL}/payment-methods/${paymentMethodId}/agentic-enrollment`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-API-KEY": CROSSMINT_CLIENT_API_KEY,
                    Authorization: `Bearer ${jwt}`,
                },
                body: JSON.stringify({ email }),
            }
        );

        return response.json();
    }
    ```

    Example response:

    ```json theme={null}
    {
        "enrollmentId": "enr_abc123",
        "status": "pending",
        "verificationConfig": {
            "environment": "test",
            "publicApiKey": "YOUR_PUBLIC_API_KEY"
        }
    }
    ```
  </Step>

  <Step title="Render the verification component">
    Pass the pending enrollment response to the `PaymentMethodAgenticEnrollmentVerification` component. It runs the full device-binding ceremony inside your UI — the user receives an email code, enters it, and then creates a passkey bound to the current device.

    ```tsx theme={null}
    import { PaymentMethodAgenticEnrollmentVerification } from "@crossmint/client-sdk-react-ui";

    function EnrollCardStep({ enrollment }: { enrollment: PendingEnrollment }) {
        return (
            <PaymentMethodAgenticEnrollmentVerification
                enrollment={enrollment}
                onVerificationComplete={() => {
                    console.log("Card is now enrolled for agentic use");
                }}
                onVerificationError={(error) => {
                    console.error("Enrollment verification failed", error);
                }}
            />
        );
    }
    ```

    When `onVerificationComplete` fires, the server has flipped the enrollment to `active`. The card is now ready for virtual card issuance.
  </Step>
</Steps>

## Understanding the Verification Flow

The `PaymentMethodAgenticEnrollmentVerification` component runs the following sequence in order:

1. The server sends a one-time code to the user's email.
2. The user enters the code in the component's UI.
3. The component prompts the browser to create a passkey bound to this device.
4. The server marks the enrollment `active`.

**The email code and the passkey are not two separate checks.** The email code proves the user owns the account; the passkey then binds the device so that future virtual card authorizations can skip the email step. Both are part of a single device-binding ceremony.

## Common Gotchas

<AccordionGroup>
  <Accordion title="The email step only happens during enrollment">
    Once a card is enrolled, all subsequent virtual card authorizations use the passkey alone. If you see the email code prompt on a non-enrollment flow, the device is not yet bound — complete enrollment first.
  </Accordion>

  <Accordion title="A passkey is bound to a single device and browser profile">
    If the user clears browser state, switches browsers, or moves to a new device, they may be asked to re-enroll for future actions on that new device.
  </Accordion>

  <Accordion title="Enrollment is per payment method, not per agent">
    Once a card is enrolled, any agent on the account can have virtual cards issued from it.
  </Accordion>
</AccordionGroup>

## What Is Next

With the card enrolled, the last step in this setup path is to [Create a Virtual Card](/agents/payment-methods/cards/create-virtual-card) so your agent can issue scoped cards with spending limits against the enrolled payment method.
