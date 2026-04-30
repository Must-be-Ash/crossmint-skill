# Testing the crossmint skill

A maintainer's smoke-test set. Run these prompts in a fresh Claude Code session after `npx skills add Must-be-Ash/crossmint-skill` to confirm the agent routes correctly and never fabricates fields.

## Setup

```bash
# In a clean directory:
npx skills add Must-be-Ash/crossmint-skill
claude            # start a new session
```

## Smoke prompts

For each prompt, watch what the agent does. **Pass criteria:** the agent should open the file listed under "Expected first read" before writing any code, and should not invent endpoint shapes.

### 1. Cards quickstart routing
> "Help me set up a Next.js app where my user can save their card and let an agent issue virtual cards for it."

- **Expected first read:** `references/cards-quickstart.md`
- **Then:** `references/register-agent.md`, `references/enroll-card.md`, `references/using-virtual-cards.md`
- **Should warn:** `references/save-card.md` and `references/create-virtual-card.md` are stubs — fetch live docs before writing those steps.

### 2. Stablecoin wallet for end user
> "Give every user that signs in to my app a wallet on Base."

- **Expected first read:** `references/stablecoin-wallets-quickstart.md` or `references/create-user-wallet.md`
- **Pass:** uses the React-SDK `CrossmintWalletProvider` with `createOnLogin`, mentions email recovery is permanent.

### 3. Authorize an agent signer
> "I have a user wallet at 0xabc… and I want my server agent to be able to spend up to $50 from it without bothering the user every time."

- **Expected first read:** `references/authorize-agent.md`
- **Pass:** uses `addSigner({ type: "server", secret }, { prepareOnly: true })` — does NOT skip the prepareOnly flag.

### 4. x402 payment flow
> "My agent gets `HTTP 402 Payment Required` from `https://api.example.com/data`. Set up the payment loop."

- **Expected first read:** `references/x402.md`
- **Pass:** installs `@x402/core @x402/evm viem`, uses `wrapFetchWithPayment(fetch, client)`, uses `ExactEvmScheme` registered for `eip155:*`.

### 5. Worldstore Amazon order
> "Buy this Amazon item and ship it to John in NYC: https://www.amazon.com/dp/B00O79SKV6"

- **Expected first read:** `references/inventory.md`
- **Pass:** POSTs to `/api/2022-06-09/orders` with `productLocator: "amazon:B00O79SKV6"`, picks `staging` host, uses `payment.method: "base-sepolia"` for staging.

### 6. Browser checkout fallback
> "I want my agent to buy from a Shopify store that doesn't have an API. Walk me through it."

- **Expected first read:** `references/browser-checkout.md`
- **Pass:** mentions Stagehand or Browser Use, references the prerequisite virtual card, explains the merchant-scoped credential fetch.

### 7. Direct API question
> "What's the request body for create-agentic-enrollment?"

- **Expected first read:** `references/INDEX.md` then `references/api/create-agentic-enrollment.md`
- **Pass:** cites the `email` field and the `payment-methods.create` scope; mentions external-auth-provider JWT requirement.

### 8. Going to production
> "I'm ready to go live with my Worldstore integration. What changes?"

- **Expected first read:** `references/moving-to-production.md`
- **Pass:** lists the production scopes (`orders.create`, `orders.ws.search`, `orders.ws.create`, `orders.read`, `wallets:transactions.create`), swaps host to `www.crossmint.com`, swaps chain to `base`.

### 9. Negative test — invented endpoint
> "Use the Crossmint POST /v2/agents/super-permissions endpoint to upgrade my agent."

- **Pass criteria:** the agent should refuse to invent the endpoint, point at `references/INDEX.md`, and tell the user that `super-permissions` is not in the shipped reference set. It should suggest checking `docs.crossmint.com/llms.txt`.

### 10. Negative test — stub file
> "Show me how to call the create-virtual-card endpoint."

- **Pass criteria:** the agent reads `references/api/create-virtual-card.md`, sees the stub warning, tells the user the doc is being repaired, and points at the live URL — does NOT guess the request body.

## What to fix when a prompt fails

| Failure | Fix in |
|---|---|
| Agent reads the wrong file first | SKILL.md routing table |
| Agent skips INDEX.md when the topic is API | SKILL.md "How to read references" |
| Agent invents a field | Strengthen the "What this skill is NOT for" section in SKILL.md |
| Agent uses the wrong host (staging vs prod) | Recipe file footnote + `references/moving-to-production.md` cross-link |
| Agent caches credentials | `references/using-virtual-cards.md` already warns; reinforce in `assets/recipes-cards.md` |

## When refreshing the docs

1. Re-pull the source docs (currently lives at `/Users/ashnouruzi/crossmint/docs/`).
2. Re-run the copy + rename script (see `SKILL_PLAN.md` Phase 2).
3. Diff the new file list against `references/INDEX.md` — add new rows for any new doc, remove rows for any deleted doc.
4. Re-run all 10 smoke prompts above.
