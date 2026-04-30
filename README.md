# crossmint — a Claude Code skill for Crossmint's agent payments stack

A Claude Code plugin that turns the official Crossmint docs into an AI-first knowledge skill. Install once and any agent in your session knows when to use **virtual cards** vs **stablecoin wallets** vs **Worldstore commerce** vs **x402 / MPP**, where to look up the exact endpoint, and how to wire it without inventing fields.

The skill ships **all 34 official docs** as references plus copy-pasteable curl + Node recipes. Nothing is summarized away — the agent gets the raw doc when it needs depth, and the SKILL.md router so it doesn't read all 34 every time.

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

## Prerequisites

- A Crossmint project + API key. Get one free at [staging.crossmint.com/console](https://staging.crossmint.com/console). Production console: [crossmint.com/console](https://www.crossmint.com/console).
- An auth provider for cards flows (Stytch, Auth0, Firebase, or any JWT issuer).
- For wallets: a `CROSSMINT_SIGNER_SECRET` (the skill walks you through generating one).

## Usage

Just describe what you want your agent to do. Examples:

> Build me a Next.js app where a user can log in with Stytch, save their card, and authorize my agent to buy stuff for them up to $100/month.

> My agent needs to pay an x402 endpoint at `api.example.com/protected`. Set up the wallet and the payment loop.

> I want my agent to buy a product on Amazon and ship it to a user. Walk me through the Worldstore integration.

> Give my server agent its own USDC wallet on Base and let it call any contract.

The skill will route to the right reference file, lift the relevant snippet from the official docs, and adapt it to your project. It will not invent endpoints — if a fact isn't in the shipped references, it points you at [docs.crossmint.com](https://docs.crossmint.com) instead.

## What's inside

```
plugins/crossmint/skills/crossmint/
├── SKILL.md                          # the router — when to read what
├── references/                       # all 34 official docs, semantic filenames
│   ├── INDEX.md                      # one-file lookup table
│   ├── overview.md
│   ├── how-agents-pay.md
│   ├── cards-quickstart.md           # + register-agent, save-card, enroll-card,
│   │                                 #   create-virtual-card, using-virtual-cards,
│   │                                 #   customize-ui, remove-cards
│   ├── stablecoin-wallets-quickstart.md  # + create-user-wallet, authorize-agent,
│   │                                 #   onramp, server-agent-wallets,
│   │                                 #   using-the-wallet, remove-agent-access
│   ├── x402.md
│   ├── mpp.md
│   ├── browser-checkout.md
│   ├── inventory.md                  # Worldstore: Amazon / Shopify / flights
│   ├── order-management.md
│   ├── moving-to-production.md
│   └── api/                          # 11 endpoint references with OpenAPI schemas
└── assets/
    ├── recipes-cards.md              # curl + Node, copy-pasteable
    ├── recipes-wallets.md
    ├── recipes-x402.md               # x402 + MPP
    └── recipes-worldstore.md
```

## Known gaps (v0.1)

Three reference files are stubs — the upstream `/docs` source folder contained byte-identical duplicates for these:

- `references/save-card.md`
- `references/create-virtual-card.md`
- `references/api/create-virtual-card.md`

Each stub contains the live URL to fetch from `docs.crossmint.com`. The skill will refuse to invent these flows. To repair: copy the real content from the live docs into the stub files and remove the warning header.

## Limitations

- **Knowledge skill, not a CLI.** The agent writes code for you to run. It does not call Crossmint APIs on your behalf, so no key handling, no billing, no auth.
- **Snapshot of the docs.** If Crossmint ships a new endpoint after the skill was last updated, the agent won't know about it until the references are refreshed.
- **Claude Code only.** Same plugin format as `recruit-skill`. Other agents can drop the `references/` folder into their context manually if they want.

## Maintainer notes

To refresh the docs:

1. Re-pull the 34 source docs from `docs.crossmint.com` (or wherever your canonical source lives) into `/Users/ashnouruzi/crossmint/docs/`.
2. Re-run the copy + rename script in `SKILL_PLAN.md` Phase 2.
3. If any new doc files appear, add them to `references/INDEX.md` and the SKILL.md routing table.

See `TESTING.md` for the smoke-test prompt set.

## License

MIT
