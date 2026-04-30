# Capabilities — what the agent can do, with what help

> **Read this BEFORE answering "can you…?"** Maps every common Crossmint ask to one of three modes:
>
> 1. **AUTO** — agent does it autonomously after Step 0 setup (API key in `~/.config/crossmint/.env`)
> 2. **WITH-USER** — agent + user together; user does the UI step (passkey, browser tap, card entry), agent runs everything else
> 3. **CODE-GEN** — agent writes code for the user's app to run (the user's app is the long-lived agent)
>
> When the user says "can you create a virtual card / wallet / pay an x402?", **answer with the mode** and the next step — don't say "no, I'm just a docs skill."

## Cards

| Ask | Mode | What the agent does | What the user does |
|---|---|---|---|
| "Create a virtual card" (for me, claude, to use) | WITH-USER | Walks through agent registration, polls enrollment status, creates the order intent, fetches credentials post-passkey | Saves card in Crossmint UI, completes passkey enrollment, taps passkey to approve mandate |
| "Save a card" | WITH-USER | Generates the React snippet, helps host the iframe page, watches logs for `paymentMethodId` | Enters card in PCI iframe |
| "Build my app's card flow" | CODE-GEN | Writes the full Next.js / Express integration | Runs the code, deploys |
| "Buy from Amazon with my card" | WITH-USER (after card saved + virtual card issued) | Fetches credentials, drives Stagehand/Browser Use, fills checkout | One-time card setup; approves spend mandate |
| "List my saved cards / virtual cards / agents" | AUTO | Calls `GET /unstable/payment-methods` etc. with the env API key | Nothing |
| "Delete a card / virtual card / agent" | AUTO | Calls the DELETE endpoint | Confirms intent first |

## Stablecoin wallets

| Ask | Mode | What the agent does | What the user does |
|---|---|---|---|
| "What's your wallet?", "do you have a wallet?", "show me your wallet" | AUTO | **`bash $SKILL_ROOT/scripts/wallet.sh info`** — idempotent get-or-create CLI. **Do NOT** hit `GET /unstable/agents` or `GET /api/2025-06-09/wallets` | Nothing |
| "Create a server agent wallet" (for the agent itself) | AUTO | Same — `wallet.sh info` creates if missing, returns existing if present | Nothing |
| "Check my wallet balance" | AUTO | **`bash $SKILL_ROOT/scripts/wallet.sh balance`** — USDC verified on-chain (no fabricated 0s), USDXM via SDK, native ETH | Nothing |
| "Fund my STAGING wallet" | WITH-USER | For x402/USDC: tell user to use [faucet.circle.com](https://faucet.circle.com/) (Base Sepolia, no auth). For USDXM-only Crossmint demos: `wallet.stagingFund(N)` SDK call | Pastes the wallet address into the faucet |
| "Send USDC to 0x…" | AUTO (with confirmation) | **`bash $SKILL_ROOT/scripts/wallet.sh send <recipient> usdc <amount>`** — confirms the action via stderr | Confirms destination + amount |
| "Sign this plain message" (EIP-191) | AUTO (with confirmation) | **`bash $SKILL_ROOT/scripts/wallet.sh sign "<message>"`** | Confirms what's being signed |
| "Sign EIP-712 typed data" | AUTO (with confirmation) | Inline Node — `EVMWallet.from(wallet).signTypedData(...)`. Read `references/wallet-actions/sign-message.md` first. Script doesn't cover typed-data yet | Confirms |
| "Call this contract function" | AUTO (with confirmation) | Inline Node — `EVMWallet.sendTransaction({ calls })` per `references/wallet-actions/send-transaction.md` | Confirms the call |
| "List my recent transfers" | AUTO | **`bash $SKILL_ROOT/scripts/wallet.sh transfers [limit]`** — defaults to USDC + status=successful | Nothing |
| "Add another signer to my wallet" | AUTO or WITH-USER (depends on recovery) | `wallet.addSigner({...}, { prepareOnly })`; user approves via OTP if recovery is email/phone | OTP if user-recovery |
| "Pay this x402 endpoint" | AUTO (with confirmation) | **`bash $SKILL_ROOT/scripts/x402.sh probe <url>`** to read requirements, confirm, then **`bash $SKILL_ROOT/scripts/x402.sh pay <url> [--max <raw>]`**. Handles v1+v2, decodes the receipt | Confirms amount + network |
| "Pay this MPP endpoint" | AUTO | Inline Node with `mppx/client` per `references/mpp.md`. No proxy script yet | Confirms |
| "Create a user wallet for my app's end users" | CODE-GEN | Writes the React `CrossmintWalletProvider` + auth setup | Runs the app |
| "Authorize my server agent on a user's wallet" | WITH-USER + CODE-GEN | Writes the `addSigner({ prepareOnly: true })` server action and the client approval handler | The end user (not the developer) approves with email code |
| "Onramp USDC to my wallet" | WITH-USER | Generates the onramp link / mounts the component | Completes the card payment in browser |

## Worldstore commerce

| Ask | Mode | What the agent does | What the user does |
|---|---|---|---|
| "Buy this Amazon ASIN and ship to <addr>" | AUTO (with confirmation) | Calls `POST /api/2022-06-09/orders`, signs + submits via the agent wallet, polls status | Confirms recipient + amount + ASIN before submission |
| "Track an order" | AUTO | Calls `GET /api/2022-06-09/orders/{id}` | Nothing |
| "Build a Worldstore integration for my app" | CODE-GEN | Writes the integration | Runs the app |
| "Refund an order" | AUTO (with confirmation) | Calls the refund endpoint per `references/order-management.md` | Confirms |

## Management / production

| Ask | Mode | What the agent does | What the user does |
|---|---|---|---|
| "What scopes do I need for production?" | AUTO (docs) | Reads `references/moving-to-production.md`, lists scopes | Nothing |
| "Switch my config to production" | AUTO | Re-runs `scripts/setup.sh --env production --api-key <new key> --force` | Provides production key |
| "Verify my setup works" | AUTO | Runs `scripts/doctor.sh` | Nothing |
| "Show me the API surface" | AUTO (docs) | Routes to `references/INDEX.md` then `references/api/*.md` | Nothing |

---

## Decision recipe — when the user says "can you do X?"

1. **Find X in the table above.** If absent, treat as CODE-GEN by default (most asks fall here).
2. **State the mode in the first sentence of your reply.** Example: "Yes — that's an AUTO action; I'll do it once you've run setup. Run `scripts/setup.sh --api-key <your key>` and tell me when it's done."
3. **Never say "I'm just a docs skill" or "I can't because I don't have credentials."** If the action is AUTO or WITH-USER, name what's needed and offer to start.
4. **Confirm before spending real money.** Anything that moves USDC, creates a real order, or charges a card requires the user to confirm the exact amount + destination first.
5. **For WITH-USER actions, show the gate clearly.** Example: "I can do steps 1, 3, 4 right now. Step 2 (saving your card) needs you to click through the iframe — I'll generate the local page for you to open."

## What the agent CANNOT do

- Hold a Crossmint card in its own name (cards must be backed by a real human's Visa/Mastercard).
- Bypass passkey / OTP steps the user must perform in a browser.
- Create production wallets / orders without a production API key from the user.
- Spend money without the user's explicit per-action confirmation.
