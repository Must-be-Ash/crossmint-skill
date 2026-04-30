# Worldstore — copy-pasteable recipes

> Lifted from `references/inventory.md` and `references/order-management.md`. Crossmint is the Merchant of Record (MoR) for these orders.

## Prerequisites

- Crossmint project + server-side API key (staging: `staging.crossmint.com/console`)
- An agent wallet on Base (or `base-sepolia` for staging) funded with USDC

For production, required scopes on the API key:
`orders.create`, `orders.ws.search`, `orders.ws.create`, `orders.read`, `wallets:transactions.create` (see `references/moving-to-production.md`).

---

## 1. Amazon — buy by ASIN

Source: `references/inventory.md` (Amazon tab).

### Step 1 — Create the order
```javascript
const baseUrl = "staging";                         // or "www" for prod
const crossmintOrder = await fetch(
  `https://${baseUrl}.crossmint.com/api/2022-06-09/orders`,
  {
    method: "POST",
    headers: {
      "X-API-KEY": process.env.CROSSMINT_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      recipient: {
        email: "john@example.com",
        physicalAddress: {
          name: "John Doe",
          line1: "ABC Street",
          city: "New York",
          state: "NY",
          postalCode: "10007",
          country: "US",
        },
      },
      locale: "en-US",
      payment: {
        receiptEmail: "john@example.com",
        method: "base-sepolia",                    // or "base" for prod
        currency: "usdc",
        payerAddress: "0x...",                     // agent's wallet
      },
      lineItems: [{ productLocator: "amazon:B00O79SKV6" }],
    }),
  }
);

const { order: paymentOrder } = await crossmintOrder.json();
```

You can include multiple `lineItems` in one order.

### Step 2 — Sign and submit payment via the agent wallet
```javascript
const baseUrl = "staging";                         // or "www" for prod
const transaction = await fetch(
  `https://${baseUrl}.crossmint.com/api/2022-06-09/wallets/${userWallet}/transactions`,
  {
    method: "POST",
    headers: {
      "X-API-KEY": process.env.CROSSMINT_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      params: {
        calls: [{
          transaction: paymentOrder.payment.preparation.serializedTransaction,
        }],
        chain: "base-sepolia",
      },
    }),
  }
);
```

### Step 3 — Poll order status
```javascript
const baseUrl = "staging";                         // or "www" for prod
const checkStatus = async (orderId) => {
  const response = await fetch(
    `https://${baseUrl}.crossmint.com/api/2022-06-09/orders/${orderId}`,
    {
      headers: { "X-API-KEY": process.env.CROSSMINT_API_KEY },
    }
  );

  const { order } = await response.json();

  switch (order.phase) {
    case "completed":
      console.log("Amazon order confirmed!");
      break;
    // …handle other phases per references/inventory.md and references/order-management.md
  }
  return order;
};
```

---

## 2. Shopify and flights

Same shape as Amazon — only the `productLocator` and any required line-item fields change. See the Shopify and Flights tabs in `references/inventory.md` for the exact locator format.

---

## 3. Refunds and delivery tracking

See `references/order-management.md` for the refund request flow and the full set of order phases.

---

## Notes

- **Staging vs production hosts.** Staging uses `staging.crossmint.com`; production uses `www.crossmint.com`. The `payment.method` chain (`base-sepolia` vs `base`) must match.
- **External wallets are also supported.** If the user is paying from an external EVM wallet (not a Crossmint wallet), see the "Alternative: Using External Wallets" snippet inside `references/inventory.md` — it sketches the ethers-based send pattern.
