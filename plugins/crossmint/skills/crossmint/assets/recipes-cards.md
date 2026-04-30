# Cards — copy-pasteable recipes

> Every snippet here is lifted directly from the reference docs. Each section names the file it came from. Adapt to your framework; do not invent fields.

## Environment

```bash
CROSSMINT_API_KEY=...                  # client-side key from staging.crossmint.com/console
CROSSMINT_BASE_URL=https://staging.crossmint.com/api/unstable
```

For production, swap `staging.crossmint.com` → `www.crossmint.com` and rotate to a production key with the right scopes (see `references/moving-to-production.md`).

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
    "X-API-KEY": process.env.CROSSMINT_API_KEY!,
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

## 2. Save a card

> Stub — `references/save-card.md` is missing real content (source duplicate). Fetch the live snippet from `https://docs.crossmint.com/agents/payment-methods/cards/save-card` before writing this step. Do **not** invent the request shape.

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
      "X-API-KEY": process.env.CROSSMINT_API_KEY!,
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

> Stub — `references/create-virtual-card.md` and `references/api/create-virtual-card.md` are missing real content (source duplicates). Fetch the live snippet from docs.crossmint.com before issuing virtual cards.

The flow returns an `orderIntentId` — persist it. Companion endpoints:
- `api/get-virtual-card.md` — GET `/order-intents/{orderIntentId}` — read status
- `api/list-virtual-cards.md` — GET `/order-intents` — list all
- `api/get-virtual-card-credentials.md` — POST `/order-intents/{orderIntentId}/credentials` — fetch PAN/expiry/CVC

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
      "X-API-KEY": process.env.CROSSMINT_API_KEY!,
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
  -H "X-API-KEY: $CROSSMINT_API_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -d '{"metadata":{"name":"Virtual Card Agent","description":"Default agent"}}'
```

### Get virtual card credentials
```bash
curl -X POST "$CROSSMINT_BASE_URL/order-intents/$ORDER_INTENT_ID/credentials" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: $CROSSMINT_API_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -d '{"merchant":{"name":"Whole Foods","url":"https://www.wholefoodsmarket.com","countryCode":"US"}}'
```
