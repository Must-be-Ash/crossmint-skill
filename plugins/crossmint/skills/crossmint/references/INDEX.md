# Reference Index

> **One-file lookup.** Find the file you need, then open just that file. Don't read everything.

---

## Decide what mode the agent is in (read first when user asks "can you…?")

| File | Read when |
|---|---|
| `capabilities.md` | User asks "can you create a wallet / virtual card / pay an endpoint?" — gives you the AUTO / WITH-USER / CODE-GEN mode + next step |

## Conceptual / start-here

| File | Read when |
|---|---|
| `overview.md` | User asks "what is Crossmint?" or wants the lay of the land |
| `how-agents-pay.md` | User is choosing between cards and stablecoins, or asking why agents need scoped payment methods |

## Cards — quickstart flow (read in order)

End-to-end: a user logs in, saves their card, authorizes an agent, and gets back a virtual card with spending mandates.

| Step | File | What it covers |
|---|---|---|
| 0 | `cards-quickstart.md` | The full 15-minute walkthrough using the virtual-cards-quickstart reference app |
| 1 | `register-agent.md` | Authenticate the user (JWT), create an `agentId` |
| 2 | `save-card.md` | Mount Crossmint's PCI-vaulted card collector (`CrossmintPaymentMethodManagement`), store a `paymentMethodId`. Includes the staging test-card matrix |
| 3 | `enroll-card.md` | One-time device-binding ceremony to authorize the saved card for agentic use |
| 4 | `create-virtual-card.md` | Issue a virtual card (order intent) with `maxAmount` / `description` / `consumer` / `prompt` mandates; passkey verification via `OrderIntentVerification` |
| 5 | `using-virtual-cards.md` | Fetch PAN, expiry, CVC for an active virtual card |
| — | `customize-ui.md` | Brand the verification + spending-authorization modals |
| — | `remove-cards.md` | Remove saved cards, delete agents, rotate virtual cards |

## Wallets — quickstart flow (read in order)

End-to-end: create a user wallet on EVM, authorize an agent as a delegated signer, optionally fund via onramp, then spend.

| Step | File | What it covers |
|---|---|---|
| 0 | `stablecoin-wallets-quickstart.md` | The full 10-minute walkthrough; introduces `xmsk1_*` signer secrets |
| 1 | `create-user-wallet.md` | Non-custodial user wallet with email or passkey recovery |
| 2 | `authorize-agent.md` | Add the agent as a delegated signer with scoped permissions (spend cap, counterparties, time window) |
| 3 | `onramp.md` | Card-to-USDC onramp so the user can fund the wallet |
| 4 | `using-the-wallet.md` | Send stablecoins, swap, bridge, or call any contract from the agent |
| — | `server-agent-wallets.md` | Backend-only wallets when there's no end user (autonomous agents) — points at `server-signer.md` for the SDK shape |
| — | **`server-signer.md`** | **Authoritative** SDK shape for server-signer wallets (`createWallet` with `recovery + alias`, `getWallet` with `evm:alias:...` locator, `useSigner`, HKDF key derivation). Read this BEFORE writing any autonomous wallet code |
| — | `remove-agent-access.md` | Revoke the agent signer |

## Paid endpoints (agentic web)

| File | Use when |
|---|---|
| `x402.md` | The agent needs to call an x402-protected endpoint. Uses `@x402/core` + `@x402/evm` + `viem` |
| `mpp.md` | The agent needs to call an MPP (Machine Payment Protocol) endpoint. Uses `mppx/client` |

Both flows assume the wallet exists and the agent is authorized as a signer (see Wallets quickstart).

## Worldstore / commerce

| File | Use when |
|---|---|
| `inventory.md` | Buy from Amazon, Shopify, or airlines via a single API. Crossmint is the Merchant of Record |
| `order-management.md` | Track delivery, request refunds |
| `browser-checkout.md` | Buy from a website that has no API — drive a real browser with a virtual card (Stagehand or Browser Use) |

## Production

| File | Use when |
|---|---|
| `moving-to-production.md` | Migrate a staging integration to live keys; lists required scopes |

---

## API endpoints (`api/` subfolder)

Terse request/response refs. Read the conceptual guide first, then come here for the exact shape.

### Agents

| File | Method | Purpose |
|---|---|---|
| `api/list-agents.md` | GET | List all agents for the authenticated user |
| `api/create-agent.md` | POST | Create a new agent |
| `api/delete-agent.md` | DELETE | Delete an agent |

### Payment methods

| File | Method | Purpose |
|---|---|---|
| `api/list-payment-methods.md` | GET | List all payment methods for the authenticated user |
| `api/delete-payment-method.md` | DELETE | Delete a payment method |

### Agentic enrollment (linking a card to an agent)

| File | Method | Purpose |
|---|---|---|
| `api/create-agentic-enrollment.md` | POST | Enroll a payment method for agentic use |
| `api/get-agentic-enrollment.md` | GET | Read enrollment status for a payment method |

### Virtual cards (order intents)

| File | Method | Purpose |
|---|---|---|
| `api/list-virtual-cards.md` | GET | List all order intents |
| `api/get-virtual-card.md` | GET | Get one order intent by ID |
| `api/create-virtual-card.md` | POST | Issue a new order intent (virtual card); scope `order-intents.create` |
| `api/get-virtual-card-credentials.md` | POST | Fetch PAN, expiry, CVC for an order intent (merchant-scoped); scope `order-intents.credentials` |

### Wallets (REST surface — for non-server-signer flows)

| File | Method | Purpose |
|---|---|---|
| `api/create-wallet.md` | POST | `POST /api/2025-06-09/wallets` — create a wallet with any admin signer (`external-wallet`, `passkey`, `email`, `phone`, or `api-key`). For server-signer wallets prefer the SDK — see `references/server-signer.md` |

---

---

## Recipes (in `assets/`)

| File | Use for |
|---|---|
| `assets/recipes-autonomous.md` | **AUTO** mode — runnable curl/Node snippets the agent invokes inline using `~/.config/crossmint/.env` |
| `assets/recipes-cards.md` | **CODE-GEN** for card integrations (register agent → save → enroll → virtual card → credentials) |
| `assets/recipes-wallets.md` | **CODE-GEN** for wallet integrations (create user wallet, authorize agent signer, spend) |
| `assets/recipes-x402.md` | x402 + MPP payment loops (works for both AUTO and CODE-GEN) |
| `assets/recipes-worldstore.md` | Amazon order: create → sign + submit via wallet → poll status |

---

## Setup scripts (in `scripts/`)

| Script | Purpose |
|---|---|
| `scripts/setup.sh` | First-run wizard. Writes `~/.config/crossmint/.env` with API key + auto-generated signer secret. Required before any AUTO action |
| `scripts/doctor.sh` | Verifies the env file is valid and the API key reaches the configured environment |

---

## Quick task → file shortcuts

- **"My agent needs to buy something on Amazon"** → `inventory.md` (preferred, has API), or `cards-quickstart.md` + `browser-checkout.md` (fallback)
- **"My agent needs to pay an API that returned 402"** → `x402.md`
- **"How do I give my agent a wallet?"** → `stablecoin-wallets-quickstart.md` → `authorize-agent.md`
- **"How do I let my agent spend up to $50/month?"** → `authorize-agent.md` (signer scope) or `create-virtual-card.md` (card mandate)
- **"User wants to top up their wallet with a card"** → `onramp.md`
- **"How do I revoke the agent's access?"** → `remove-agent-access.md` (wallets) or `remove-cards.md` (cards)
- **"Going to production"** → `moving-to-production.md`
