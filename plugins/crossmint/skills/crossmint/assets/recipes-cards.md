# Cards — copy-pasteable recipes

> Every snippet here is lifted directly from the reference docs. Each section names the file it came from. Adapt to your framework; do not invent fields.

## Environment

The cards stack uses the **client-side** Crossmint key plus a **user JWT** (Stytch / Auth0 / Crossmint Auth). Both are set up by `scripts/setup.sh` (which saves `CROSSMINT_CLIENT_API_KEY`); the JWT comes from your auth provider at request time.

```bash
CROSSMINT_CLIENT_API_KEY=ck_staging_...     # from staging.crossmint.com/console (client-side)
CROSSMINT_BASE_URL=https://staging.crossmint.com/api/unstable
USER_JWT=...                                 # session JWT for the end user
```

For production, swap `staging.crossmint.com` → `www.crossmint.com` and rotate to a production client key with the right scopes (see `references/moving-to-production.md`).

---

## 1. Register an agent for an authenticated user

Source: `references/register-agent.md`

The agent identity is per-user. Persist `agentId` on your user record.

```typescript
const BASE_URL = "https://staging.crossmint.com/api/unstable";

const response = await fetch(`${BASE_URL}/agents`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-API-KEY": process.env.CROSSMINT_CLIENT_API_KEY!,
    Authorization: `Bearer ${jwt}`,                // user's session JWT (Stytch / Auth0 / etc.)
  },
  body: JSON.stringify({
    metadata: {
      name: "Virtual Card Agent",
      description: "Default agent for virtual card issuance",
    },
  }),
});

const { agentId } = await response.json();
```

Required scope on the API key: `agents.create` (see `references/api/create-agent.md`).

---

## 2. Save a card (React, client-side only)

Source: `references/save-card.md`.

Card data is collected by Crossmint's hosted UI — your backend never sees the PAN. Render the management component on a page where the user manages their payment methods.

```tsx
"use client";
import { CrossmintProvider, CrossmintPaymentMethodManagement } from "@crossmint/client-sdk-react-ui";

function App() {
  return (
    <CrossmintProvider apiKey={process.env.NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY!}>
      <PaymentMethodsPage jwt={userJwt} />
    </CrossmintProvider>
  );
}

function PaymentMethodsPage({ jwt }: { jwt: string }) {
  const handlePaymentMethodSelected = (paymentMethod: { paymentMethodId: string }) => {
    // Persist paymentMethod.paymentMethodId on your user record.
    // Apply strict access controls — never expose in client-side storage or logs.
    console.log("Card saved:", paymentMethod.paymentMethodId);
  };

  return (
    <CrossmintPaymentMethodManagement
      jwt={jwt}
      onPaymentMethodSelected={handlePaymentMethodSelected}
    />
  );
}
```

Staging test card for the happy path: `4242 4242 4242 4242`, any future expiry, any 3-digit CVC. Full test-card matrix (issuer decline, OTP failure, ineligible card, etc.) lives in `references/save-card.md`.

---

## 3. Enroll a card for agentic use

Source: `references/enroll-card.md` and `references/api/create-agentic-enrollment.md`.

The enrollment is the device-binding ceremony. Endpoint requires a JWT from an external auth provider (Auth0, Firebase, Stytch, etc.) — Crossmint Auth is not supported here.

```typescript
const BASE_URL = "https://staging.crossmint.com/api/unstable";

const response = await fetch(
  `${BASE_URL}/payment-methods/${paymentMethodId}/agentic-enrollment`,
  {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-API-KEY": process.env.CROSSMINT_CLIENT_API_KEY!,
      Authorization: `Bearer ${jwt}`,
    },
    body: JSON.stringify({
      email: userEmail,                            // optional — used for verification
    }),
  }
);

const enrollment = await response.json();
// enrollment.status is "active" or "pending"
// If "pending", enrollment.verificationConfig contains { environment, publicApiKey } for the verification UI
```

Required scope: `payment-methods.create`.

---

## 4. Create a virtual card with spending mandates

Source: `references/create-virtual-card.md` and `references/api/create-virtual-card.md`.

A virtual card is an **order intent**. Mandates scope the spending: `maxAmount` (with currency + period), `description`, `consumer` (recipient email), and `prompt` (free-text rationale).

### 4a. Create the order intent
```typescript
const BASE_URL = "https://staging.crossmint.com/api/unstable";

const response = await fetch(`${BASE_URL}/order-intents`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-API-KEY": process.env.NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY!,
    Authorization: `Bearer ${jwt}`,
  },
  body: JSON.stringify({
    agentId,                                       // from step 1
    payment: { paymentMethodId },                  // from step 3 (enrolled card)
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
// orderIntent.orderIntentId — persist it
// orderIntent.phase — "requires-verification" or "active"
```

Required scope: `order-intents.create`. Supported `maxAmount.details.currency`: usd, eur, aud, gbp, jpy, sgd, hkd, krw, inr, vnd, cop. Supported `period`: weekly, monthly, yearly.

### 4b. Authorize via passkey (only if phase is `requires-verification`)
```tsx
import { OrderIntentVerification } from "@crossmint/client-sdk-react-ui";

function AuthorizeSpending({ orderIntent }: { orderIntent: any }) {
  return (
    <OrderIntentVerification
      orderIntent={orderIntent}
      onVerificationComplete={() => console.log("Virtual card is now active")}
      onVerificationError={() => console.error("Spending authorization failed")}
    />
  );
}
```

This step is **passkey-only** — no email code; the email verification was completed during enrollment. After `onVerificationComplete` fires, the phase moves to `active` and credentials can be fetched (step 5).

### What to persist

| Data | When |
|---|---|
| `orderIntentId` | Always — every later operation keys off it |
| Merchant descriptor (`name`, `url`, `countryCode`) | When you'll repeatedly charge the same merchant — saves re-collecting it on every credential fetch |
| Card credentials | Never — they're short-lived and merchant-scoped |

---

## 5. Fetch the virtual card credentials

Source: `references/using-virtual-cards.md`.

Credentials are merchant-scoped — pass the merchant on every call. Don't cache: the returned card has its own short-lived `expiresAt`.

```typescript
const BASE_URL = "https://staging.crossmint.com/api/unstable";

const response = await fetch(
  `${BASE_URL}/order-intents/${orderIntentId}/credentials`,
  {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-API-KEY": process.env.CROSSMINT_CLIENT_API_KEY!,
      Authorization: `Bearer ${jwt}`,
    },
    body: JSON.stringify({
      merchant: {
        name: "Whole Foods",
        url: "https://www.wholefoodsmarket.com",
        countryCode: "US",                         // ISO 3166-1 alpha-2
      },
    }),
  }
);

const { card, expiresAt } = await response.json();
// card.number, card.expirationMonth, card.expirationYear, card.cvc
```

Required scope: `order-intents.credentials`.

---

## curl equivalents (for non-Node stacks)

### Create agent
```bash
curl -X POST "$CROSSMINT_BASE_URL/agents" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: $CROSSMINT_CLIENT_API_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -d '{"metadata":{"name":"Virtual Card Agent","description":"Default agent"}}'
```

### Get virtual card credentials
```bash
curl -X POST "$CROSSMINT_BASE_URL/order-intents/$ORDER_INTENT_ID/credentials" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: $CROSSMINT_CLIENT_API_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -d '{"merchant":{"name":"Whole Foods","url":"https://www.wholefoodsmarket.com","countryCode":"US"}}'
```
