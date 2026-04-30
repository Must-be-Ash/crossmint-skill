---
name: crossmint
description: Build agents that pay using Crossmint — virtual credit cards (PCI-vaulted, network-enforced spend limits via Visa VIC / Mastercard Agent Pay), stablecoin wallets on Base/EVM with delegated agent signers, x402 and MPP pay-per-call endpoints, and Worldstore commerce for buying from Amazon, Shopify, and airlines via a single API. Use when the user asks how to issue a virtual card for an agent, give an agent a wallet, authorize an agent as a signer, pay an x402-protected or MPP-protected endpoint, place an order on behalf of a user, set up agentic enrollment, manage payment methods, or move a Crossmint integration to production. Routes the agent to the exact reference file and recipe needed — never invents endpoints or fields.
---

# Crossmint

## Overview

Crossmint provides two payment primitives for agents — **cards** (for the traditional web: Amazon, Shopify, SaaS checkouts) and **stablecoin wallets** (for the agentic web: x402, MPP, machine-to-machine settlement). This skill ships the complete official docs and tells you which file to read for the task at hand.

**Always**: open `references/INDEX.md` first when in doubt. It's a one-file lookup table that maps any task to the right reference.

## What this skill is for

- Issuing virtual cards for an agent with spending mandates (amount, merchant, expiry)
- Creating user wallets and server agent wallets on EVM (Base) or Solana
- Authorizing an agent as a delegated signer with scoped permissions
- Paying x402-protected endpoints (the @x402/core flow)
- Paying MPP endpoints (the mppx/client flow)
- Placing Worldstore orders (Amazon, Shopify, flights — Crossmint is Merchant of Record)
- Managing agentic enrollments, payment methods, agents (CRUD via the Agentic Payments API)
- Moving a staging integration to production (project, keys, scopes)
- Customizing the Crossmint UI components

## What this skill is NOT for

- Inventing endpoint shapes, field names, or scopes that aren't in `references/`. If a fact isn't in a reference file, fetch the live docs at `https://docs.crossmint.com/llms.txt` rather than guessing.
- Acting as a hosted CLI / SDK on the user's behalf — this skill is knowledge + recipes, not a payment client. The user runs the code; you write it for them based on the references.
- Non-Crossmint payment providers.

## Prerequisites

Before writing any Crossmint integration code, confirm:

1. **Crossmint project + API key.** Staging at `https://staging.crossmint.com/console`, production at `https://www.crossmint.com/console`. The user creates the project; you ask them which environment they want to start in (default: staging).
2. **API key scopes** match what the flow needs. Each `references/api/*.md` file lists the required scope at the top. For Worldstore in production: `orders.create`, `orders.ws.search`, `orders.ws.create`, `orders.read`, `wallets:transactions.create`.
3. **Auth provider** for cards flows. The cards quickstart uses Stytch as an example; any JWT-issuing auth provider works.
4. **For wallets**: a `CROSSMINT_SIGNER_SECRET` (format: `xmsk1_<64-hex>`) — generated client-side, stored in env. See `references/stablecoin-wallets-quickstart.md`.

If the user hasn't set these up, walk them through it before writing integration code. Never put a real API key in a code sample — use `process.env.CROSSMINT_API_KEY`.

## Routing — pick the branch first

Triage the user's request into one of these branches, then read the listed file before answering. **Multi-intent requests read multiple branches in parallel.**

| User intent | Branch | First file |
|---|---|---|
| "credit card", "virtual card", "Amazon purchase via card", "checkout form fill" | **Cards** | `references/cards-quickstart.md` |
| "wallet", "USDC", "stablecoin", "on-chain", "Base", "EVM", "Solana" | **Wallets** | `references/stablecoin-wallets-quickstart.md` |
| "x402", "402 payment", "pay-per-call API" | **x402** | `references/x402.md` |
| "MPP", "machine payment protocol" | **MPP** | `references/mpp.md` |
| "buy on Amazon / Shopify", "ship a product", "1B products", "Worldstore", "flights" | **Commerce** | `references/inventory.md` |
| "browser checkout", "fill a website checkout", "Stagehand", "Browser Use" | **Browser** | `references/browser-checkout.md` |
| "production", "live keys", "go live", "switch from staging" | **Production** | `references/moving-to-production.md` |
| Direct API question (list / create / delete / get) | **API** | `references/INDEX.md` then `references/api/*.md` |
| "what is Crossmint?", "compare cards vs wallets" | **Conceptual** | `references/overview.md` then `references/how-agents-pay.md` |

## How to read references

1. **Start with `references/INDEX.md`** — it's the table of every reference file with a one-line summary. Open it first if you're not 100% sure which file you need.
2. **Open at most 2–3 reference files per task.** Each is short and self-contained. Don't read everything.
3. **For multi-step flows** (e.g. cards quickstart), follow the order embedded in the quickstart: `register-agent.md` → `save-card.md` → `enroll-card.md` → `create-virtual-card.md` → `using-virtual-cards.md`.
4. **API endpoint refs** (`references/api/*.md`) live separately because they're terser. Read the conceptual guide first, then the endpoint ref for the exact request/response shape.

## Recipes

`assets/` contains copy-pasteable curl + Node snippets for the most common ops, drawn directly from the reference docs:

- `assets/recipes-cards.md` — register agent → save card → enroll → create virtual card → fetch credentials
- `assets/recipes-wallets.md` — create wallet → authorize agent signer → check balance → spend
- `assets/recipes-x402.md` — install `@x402/core`, the GET-with-pay loop, error handling
- `assets/recipes-worldstore.md` — Amazon search → create order → poll status → ship

Use these as starting points; adapt to the user's framework. **Always cite the reference file the snippet came from** so the user can verify.

## Known gaps in v0.1

Three reference files are stubs because the source docs were duplicates:

- `references/save-card.md`
- `references/create-virtual-card.md`
- `references/api/create-virtual-card.md`

If the user lands in any of these, fetch the live equivalent from `https://docs.crossmint.com/llms.txt` rather than guessing. Each stub file contains the exact URL to fetch.

## Output style

- Write code the user can run as-is. Prefer Node + fetch (or curl) for portability; use `@crossmint/wallets-sdk` and `@crossmint/client-sdk-react-ui` when the user is in a React app.
- For multi-step flows, show the sequence with numbered steps and label each step with the file it came from (e.g. "from `references/enroll-card.md`").
- Always state which environment (staging vs production) the snippet targets.
- Never invent. If the reference doesn't show a field, say "not documented in the shipped references — verify at docs.crossmint.com".
