# crossmint — a Claude Code skill for Crossmint's agent payments stack

A Claude Code plugin that lets your agent **actually use** Crossmint — not just read about it. Install once, hand it your Crossmint API key, and the agent can:

- Create a server agent wallet on Base and spend USDC autonomously
- Pay x402 and MPP endpoints
- Place Worldstore orders for Amazon / Shopify / flights
- List, create, and delete agents, payment methods, and virtual cards
- Walk you through the human-gated flows (saving a card in the PCI iframe, passkey enrollment, approving a spend mandate) and run every API call around the human step
- Generate working Next.js / Express integration code when you're building an app

The skill ships **all 34 official Crossmint docs** as references plus runnable curl / Node recipes. The SKILL.md router decides — for every "can you…?" — whether the action is **AUTO** (agent does it), **WITH-USER** (you click, it calls), or **CODE-GEN** (it writes app code for you to deploy). No hallucinated endpoints; everything maps back to a shipped reference file.

## What you get

- **Cards** — virtual credit cards with PCI-vaulted PAN, network-enforced spend limits via Visa VIC and Mastercard Agent Pay, agentic enrollment, browser checkout (Stagehand / Browser Use)
- **Stablecoin wallets** — non-custodial user wallets and server agent wallets on Base/EVM and Solana, delegated agent signers with scoped permissions, onramp via card
- **x402 + MPP** — pay 402-protected and Machine Payment Protocol endpoints from the agent's wallet
- **Worldstore commerce** — buy from Amazon, Shopify, and airlines via a single API; Crossmint is the Merchant of Record
- **Production playbook** — staging → live keys, required scopes, environment switches

## Install

```bash
npx skills add Must-be-Ash/crossmint-skill
```

Then start a new Claude Code session and the `crossmint` skill is available.

## First-run setup

The first time you ask the agent to do something autonomous (create a wallet, pay an endpoint, place an order), it will ask for your Crossmint API key. Get one free at [staging.crossmint.com/console](https://staging.crossmint.com/console) → Projects → API Keys → server-side key with all scopes. Paste it into chat and the agent runs `scripts/setup.sh` to save it (with an auto-generated signer secret) to `~/.config/crossmint/.env` (mode 600).

Run `scripts/doctor.sh` any time to verify the config still works:
```bash
bash ~/.claude/plugins/cache/<...>/scripts/doctor.sh
```

If you only want code-gen help (you're building an app), say "skip setup" and the agent will go straight to writing code without touching your API key.

## Prerequisites

- A Crossmint project + API key (free, takes ~2 minutes at the link above)
- For card flows in your own app: an auth provider (Stytch, Auth0, Firebase, or any JWT issuer)
- For x402 / on-chain calls the agent makes itself: enough USDC in the agent wallet on Base. The agent will tell you the address and balance before any spend.

## Usage

Just describe what you want. The agent picks the mode and either runs it, walks you through it, or writes the code.

### "Do it for me" (AUTO)
> Create a wallet for yourself on Base, then check the balance.

> Pay this x402 endpoint and show me the response: `https://api.example.com/protected`

> Buy this Amazon item and ship to John in NYC: `https://www.amazon.com/dp/B00O79SKV6`

> List all the agents and virtual cards I currently have.

### "Do it with me" (WITH-USER)
> Issue a virtual card backed by my Visa, capped at $50/month for grocery purchases.

> Authorize my server agent on this user wallet so it can spend on their behalf.

### "Build my app" (CODE-GEN)
> Build a Next.js app where users log in with Stytch, save their card, and authorize my agent.

> Generate the React provider setup so my end users get an embedded wallet on sign-in.

The agent never invents endpoints — if a fact isn't in the shipped references, it points you at [docs.crossmint.com](https://docs.crossmint.com) instead. Before any spend, it shows the exact action and waits for your confirmation.

## CLI proxy tools (the agent invokes these for hot ops)

Same pattern as `setup.sh` / `doctor.sh` — the skill ships a script, the agent runs it via `bash $SKILL_ROOT/scripts/<name>`, you get deterministic JSON. No re-derivation per session.

| Command | Returns |
|---|---|
| `wallet.sh info` | `{address, alias, chain, env, created}` (idempotent get-or-create) |
| `wallet.sh balance` | `{usdc:{amount,raw,contract,sdkAgrees}, usdxm, native}` (USDC verified on-chain) |
| `wallet.sh send <to> <token> <amount>` | `{hash, explorer, ...}` |
| `wallet.sh transfers [limit]` | `{count, source, transfers:[…]}` |
| `wallet.sh sign "<message>"` | `{message, signature, signer}` |
| `x402.sh probe <url>` | `{isX402, x402Version, network, maxAmountRequired, maxAmountUSD, payTo, …}` (no spend) |
| `x402.sh pay <url> [--max <raw>]` | `{paidStatus, paidBody, receipt, paymentRequired}` |

Stdout is pure JSON. Stderr carries SDK chatter and confirmations. First run installs the runtime under `~/.cache/crossmint-skill/` (~30s); after that, every call is fast.

## What's inside

```
plugins/crossmint/skills/crossmint/
├── SKILL.md                          # the router + Step 0 setup wizard
├── scripts/
│   ├── setup.sh                      # writes ~/.config/crossmint/.env (API key + signer secret)
│   ├── doctor.sh                     # verifies config + API key reachability
│   ├── wallet.sh                     # info | balance | send | transfers | sign
│   ├── x402.sh                       # probe | pay
│   └── lib/                          # runtime.sh + Node engines for each subcommand
├── references/                       # all 34 official docs, semantic filenames
│   ├── INDEX.md                      # one-file lookup over every reference
│   ├── capabilities.md               # AUTO / WITH-USER / CODE-GEN per common ask
│   ├── overview.md, how-agents-pay.md
│   ├── cards-quickstart.md           # + register-agent, save-card, enroll-card,
│   │                                 #   create-virtual-card, using-virtual-cards,
│   │                                 #   customize-ui, remove-cards
│   ├── stablecoin-wallets-quickstart.md  # + create-user-wallet, authorize-agent,
│   │                                 #   onramp, server-agent-wallets,
│   │                                 #   using-the-wallet, remove-agent-access
│   ├── x402.md, mpp.md, browser-checkout.md
│   ├── inventory.md, order-management.md
│   ├── moving-to-production.md
│   └── api/                          # 11 endpoint references with OpenAPI schemas
└── assets/
    ├── recipes-autonomous.md         # runnable inline (env-aware curl + Node)
    ├── recipes-cards.md              # CODE-GEN — full integration
    ├── recipes-wallets.md            # CODE-GEN
    ├── recipes-x402.md               # x402 + MPP
    └── recipes-worldstore.md         # Amazon / Shopify / flights
```

## Limitations

- **No card in Claude's name.** Crossmint cards must be backed by a real human's Visa/Mastercard. The agent can spend USDC from a wallet it controls; it cannot issue a card to itself. (For autonomous spending, use the wallet path.)
- **Passkey / browser steps are still yours.** The agent can drive every API call, but if a flow requires you to tap a passkey or enter a card in a PCI iframe, you do that part. The agent waits.
- **Snapshot of the docs.** If Crossmint ships a new endpoint after the skill was last updated, the agent won't know about it until the references are refreshed (see `TESTING.md` for the refresh procedure).
- **Spending requires per-action confirmation.** Read-only API calls run freely. Anything that moves USDC, creates an order, or charges a card always shows the exact action and waits for your "yes" first.
- **Claude Code only.** Same plugin format as `recruit-skill`. Other agents can drop the `references/` folder into their context manually if they want.

## Maintainer notes

To refresh the docs:

1. Re-pull the 34 source docs from `docs.crossmint.com` (or wherever your canonical source lives) into `/Users/ashnouruzi/crossmint/docs/`.
2. Re-run the copy + rename script in `SKILL_PLAN.md` Phase 2.
3. If any new doc files appear, add them to `references/INDEX.md` and the SKILL.md routing table.

See `TESTING.md` for the smoke-test prompt set.

## License

MIT
