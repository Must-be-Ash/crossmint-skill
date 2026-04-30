---
name: crossmint
description: Use Crossmint to actually pay for things, get a wallet, or issue a virtual card — not just talk about it. The agent itself can create a server agent wallet on Base, list/manage agents and payment methods, place Worldstore orders for Amazon/Shopify/flights, and pay x402 or MPP endpoints autonomously once the user provides a Crossmint API key (saved to ~/.config/crossmint/.env). For flows that need a human (saving a card in the PCI iframe, passkey enrollment, approving a spend mandate), the agent guides the user step-by-step and runs every API call around the human gate. Also generates working Next.js / Express integration code when the user is building an app, never inventing endpoints. Use whenever the user asks to "get a wallet", "create a virtual card", "pay this endpoint", "buy something", "give my agent money", "set up Crossmint", or any related ask. Ships all 34 official docs as references plus runnable curl/Node recipes.
---

# Crossmint

Crossmint gives agents two payment primitives — **virtual cards** (traditional web: Amazon, Shopify, SaaS) and **stablecoin wallets** (agentic web: x402, MPP, USDC on Base). This skill turns the docs into action: the agent runs Crossmint API calls inline using the user's API key, walks the user through the human-gated parts (passkey, card iframe), and writes integration code for app-building tasks.

> **Core rule**: when the user asks "can you do X?", **answer with the mode** — AUTO / WITH-USER / CODE-GEN — and the next concrete step. Never say "I'm just a docs skill." Read `references/capabilities.md` for the full mode mapping.

---

## Step 0 — first-run setup (do this before any AUTO or WITH-USER action)

The agent runs API calls using credentials at `~/.config/crossmint/.env`. **Detect first run** by checking if that file exists:

```bash
[ -f "${HOME}/.config/crossmint/.env" ] && grep -q "^SETUP_COMPLETE=true$" "${HOME}/.config/crossmint/.env" && echo READY || echo SETUP_NEEDED
```

- **READY**: skip to the user's request silently. **Do NOT announce "setup is complete"** — the user knows.
- **SETUP_NEEDED**: tell the user what you need, and only when they confirm, run setup.

### Setup wizard flow

When setup is needed AND the user is asking for something AUTO/WITH-USER:

1. Tell them: **"I can do that, but I need Crossmint API keys first. Get them (free) at https://staging.crossmint.com/console/projects/apiKeys."** Then ask them to paste **one or both**:

   - **Server-side key (`sk_staging_*`)** — required for wallets, x402, MPP, Worldstore, all autonomous flows.
   - **Client-side key (`ck_staging_*`)** — required for cards stack: agents, payment methods, virtual cards (issuance + listing + credentials), agentic enrollments. Most cards calls also need a user JWT (Stytch / Auth0 / Crossmint Auth).

   Recommend grabbing **both** up front so you don't have to re-run setup later. If they only know they need one, default to whichever matches the immediate task.
2. **Locate the scripts.** When the skill is installed via `npx skills add`, scripts live somewhere under `~/.claude/plugins/`. Resolve the path once:
   ```bash
   SKILL_ROOT=$(find "${HOME}/.claude" -type d -path '*/skills/crossmint' 2>/dev/null | head -1)
   echo "SKILL_ROOT=${SKILL_ROOT}"
   ```
3. Run setup with whatever they provided:
   ```bash
   # Both keys (recommended)
   bash "${SKILL_ROOT}/scripts/setup.sh" --server-key sk_... --client-key ck_... --env staging

   # Only one (legacy --api-key auto-routes by prefix)
   bash "${SKILL_ROOT}/scripts/setup.sh" --api-key "<sk_... or ck_...>" --env staging
   ```
   For production, pass `--env production`. The script auto-generates a `CROSSMINT_SIGNER_SECRET` (xmsk1_…) and writes everything to `~/.config/crossmint/.env` with mode 600.

   To **add the missing key later** (e.g. user started with server, now needs client for cards), re-run with both keys + `--force`:
   ```bash
   bash "${SKILL_ROOT}/scripts/setup.sh" \
     --server-key "$(grep ^CROSSMINT_SERVER_API_KEY ~/.config/crossmint/.env | cut -d= -f2-)" \
     --client-key ck_... \
     --signer-secret "$(grep ^CROSSMINT_SIGNER_SECRET ~/.config/crossmint/.env | cut -d= -f2-)" \
     --env staging --force
   ```
   (The `--signer-secret` reuse is critical — otherwise you'd derive a new wallet address.)
4. Verify the key works:
   ```bash
   bash "${SKILL_ROOT}/scripts/doctor.sh"
   ```
   Doctor probes `GET /unstable/agents`. On 200 → proceed. On 401/403 → tell the user the key was rejected and ask them to confirm the environment + scopes.
5. Once doctor passes, **proceed with the original ask immediately**. Don't ask "what next?" — they already told you.

### Loading config inside any later command

Every snippet in `assets/recipes-autonomous.md` starts with:
```bash
( set -a; source "${HOME}/.config/crossmint/.env"; set +a; <command using env vars> )
```
This scopes the secrets to a subshell so they don't leak.

### When the user has not done setup yet but asks a CODE-GEN question

CODE-GEN tasks (e.g. "write me a Next.js card integration") **do not require Step 0** — go ahead and generate code. Mention setup only if they later want to test it autonomously.

---

## What the agent can do — the three modes

Read `references/capabilities.md` for the full per-ask table. Summary:

- **AUTO** — agent does it autonomously after Step 0. Examples: list agents, create a server agent wallet, place a Worldstore order, pay an x402 endpoint, get virtual card credentials. Recipes in `assets/recipes-autonomous.md`.
- **WITH-USER** — agent + user together; user does the UI step (saving a card, passkey approval). Agent runs every API call around the human gate. Examples: end-to-end virtual card issuance, agent signer authorization on a user wallet, onramp.
- **CODE-GEN** — agent writes app code for the user's product (the user's app is the long-lived agent). Examples: full Next.js card flow, Express server signer, React `CrossmintWalletProvider` setup. Recipes in `assets/recipes-cards.md`, `recipes-wallets.md`, `recipes-x402.md`, `recipes-worldstore.md`.

**Default to the most-actionable mode.** If "create a virtual card for me" can be done WITH-USER, offer that path first; only fall back to CODE-GEN if the user clarifies they're building an app.

---

## Routing — pick the doc branch

After resolving mode, drill into the right reference. Multi-intent requests read multiple branches in parallel.

| User intent | First file |
|---|---|
| "what's your wallet", "do you have a wallet", "show me your wallet", "what address" | **Run `bash $SKILL_ROOT/scripts/wallet.sh info`** — get-or-create CLI, returns `{address, alias, chain, env, created}`. Do NOT free-form a Node script. |
| "what's my balance", "how much USDC do I have" | **Run `bash $SKILL_ROOT/scripts/wallet.sh balance`** — verifies USDC on-chain (real session bug: SDK sometimes under-reports). Returns `{usdc:{amount,raw,contract,sdkAgrees}, usdxm, native}`. |
| "send X USDC to Y", "transfer", "pay this address" | **Run `bash $SKILL_ROOT/scripts/wallet.sh send <recipient> <token> <amount>`** — confirm the action with the user FIRST. |
| "list my recent transfers", "transfer history" | **Run `bash $SKILL_ROOT/scripts/wallet.sh transfers [limit]`** — defaults to USDC + status=successful. |
| "sign a message" (EIP-191 plain) | **Run `bash $SKILL_ROOT/scripts/wallet.sh sign "<message>"`** |
| "pay this x402 endpoint <URL>" | **`bash $SKILL_ROOT/scripts/x402.sh probe <url>`** first (read amount + network), confirm with user, then **`bash $SKILL_ROOT/scripts/x402.sh pay <url> [--max <raw>]`**. Probe never spends. |
| "credit card", "virtual card", "Amazon purchase via card", "checkout form fill" | `references/cards-quickstart.md` |
| "create a wallet for me / for my agent", autonomous wallet | `references/server-signer.md` then `references/wallet-actions/create-wallet.md` |
| "wallet", "USDC", "stablecoin", "on-chain", "Base", "EVM", "Solana" (user wallet flows) | `references/wallet-quickstart-node.md`, `wallet-quickstart-react.md`, or `wallet-quickstart-rest.md` depending on stack |
| "send USDC", "transfer tokens" | `references/wallet-actions/transfer-tokens.md` |
| "wallet balance", "how much USDC do I have" | `references/wallet-actions/check-balances.md` |
| "sign a message", "EIP-712", "typed data" | `references/wallet-actions/sign-message.md` |
| "call a contract", "send a transaction" | `references/wallet-actions/send-transaction.md` |
| "transfer history", "list past transfers" | `references/wallet-actions/list-transfers.md` |
| "add another signer to a wallet" | `references/wallet-actions/add-signers.md` |
| "what methods does the wallet have", "get a past transaction by id", "wallet.recover" | `references/wallet-actions/wallet-methods.md` |
| "list NFTs", "wallet NFT balances" | `references/wallet-actions/check-balances.md` (NFT Balances tab) |
| "frictionless on-device signing", "no OTP for signing", "device signer + server-created wallet" | `references/server-wallet-with-device-signer.md` |
| "configure CrossmintProvider / AuthProvider / WalletProvider props" | `references/react-providers.md` |
| "x402", "402 payment", "pay-per-call API" | `references/x402.md` (probe-first, v1+v2 support; overrides the live Crossmint doc) — and `references/funding-staging-wallets.md` if balance is 0 (x402 needs **USDC**, not USDXM) |
| "fund my wallet", "I have no USDC", "wallet is empty" | `references/funding-staging-wallets.md` |
| "MPP", "machine payment protocol" | `references/mpp.md` |
| "buy on Amazon / Shopify", "ship a product", "Worldstore", "flights" | `references/inventory.md` |
| "browser checkout", "fill a website checkout", "Stagehand", "Browser Use" | `references/browser-checkout.md` |
| "production", "live keys", "go live" | `references/moving-to-production.md` |
| Direct API question (list/create/delete/get) | `references/INDEX.md` then `references/api/*.md` |
| "what is Crossmint?", "compare cards vs wallets" | `references/overview.md` then `references/how-agents-pay.md` |

When unsure, open `references/INDEX.md` — it's the one-file lookup over all 34 references.

---

## Safety — confirm before spending

For any action that moves real USDC, charges a card, or creates a real order, **show the user the exact action first** (destination, amount, endpoint) and wait for explicit "yes" before submitting. The agent's autonomy stops at unconfirmed mutations.

Read-only calls (list agents, list payment methods, get order status) need no confirmation — run them freely.

---

## How to read references

1. **`references/INDEX.md` first** when you're not 100% sure which file. Quick lookup over all 34.
2. **`references/capabilities.md`** when the user asks "can you…?" — gives you the mode + next step.
3. **At most 2–3 reference files per task.** Each is short.
4. **Multi-step flows** follow the embedded order: e.g. cards = `register-agent.md` → `save-card.md` → `enroll-card.md` → `create-virtual-card.md` → `using-virtual-cards.md`.
5. **API endpoint refs** (`references/api/*.md`) are terser — read the conceptual guide first, then the endpoint ref for the exact request/response shape.

---

## Recipes

- `assets/recipes-autonomous.md` — **runnable** curl/Node snippets the agent invokes inline (uses `~/.config/crossmint/.env`). For AUTO actions.
- `assets/recipes-cards.md` — full cards integration: register agent → save card → enroll → create virtual card → fetch credentials. For CODE-GEN.
- `assets/recipes-wallets.md` — create wallet → authorize agent signer → spend. For CODE-GEN.
- `assets/recipes-x402.md` — `@x402/core` payment loop. For CODE-GEN and AUTO (variants).
- `assets/recipes-worldstore.md` — Amazon order: create → sign+submit → poll. For CODE-GEN.

Always cite the reference file a snippet came from so the user can verify.

---

## Lessons from real sessions — bake these in before writing any wallet code

These are the bugs that the agent has actually hit. Trust the references, don't guess.

1. **The `@crossmint/wallets-sdk` `createWallet` shape is `recovery + alias`, NOT `signer + owner`.** The `signer:` field does not exist on `createWallet`. The `owner:` field is for user-bound wallets, not server-signer ones — use `alias:` instead. Source: `references/server-signer.md`.

   ```typescript
   // ✅ CORRECT — server agent wallet
   const wallet = await wallets.createWallet({
     chain: "base-sepolia",
     recovery: { type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET },
     alias: "my-server-wallet",
   });
   ```

2. **Retrieve a server wallet by `evm:alias:<your-alias>`.** Then call `wallet.useSigner({ type: "server", secret })` before any signing op. Skipping `useSigner` is the second-most-common bug.

3. **Server-side key ≠ client-side key — pick the right env var per call.** The setup wizard saves both `CROSSMINT_SERVER_API_KEY` and `CROSSMINT_CLIENT_API_KEY` to `~/.config/crossmint/.env`. Always read the right one for the call:

   | Call surface | Env var | Notes |
   |---|---|---|
   | `@crossmint/wallets-sdk` (createWallet, getWallet, send, balances, signTypedData, x402, …) | `CROSSMINT_SERVER_API_KEY` | + `CROSSMINT_SIGNER_SECRET` |
   | `POST /api/2025-06-09/wallets/...` and `/transactions` | `CROSSMINT_SERVER_API_KEY` | |
   | Worldstore: `POST /api/2022-06-09/orders` | `CROSSMINT_SERVER_API_KEY` | |
   | `GET/POST /api/unstable/agents` | `CROSSMINT_CLIENT_API_KEY` | + `Authorization: Bearer <user JWT>` |
   | `GET/POST /api/unstable/payment-methods` (and `/agentic-enrollment`) | `CROSSMINT_CLIENT_API_KEY` | + user JWT |
   | `GET/POST /api/unstable/order-intents` (virtual cards: list, issue, credentials) | `CROSSMINT_CLIENT_API_KEY` | + user JWT |

   The legacy `CROSSMINT_API_KEY` env var still exists in the file for backward compat with older recipes; it points at whichever was provided first. **Prefer the explicit `*_SERVER_API_KEY` / `*_CLIENT_API_KEY` names** in any new code you write.

   `scripts/doctor.sh` probes both keys against their canonical endpoints and reports which work.

4. **Server-signer wallets cannot be created via REST alone.** The secret stays on your server; the SDK does HKDF derivation locally to compute the address. If the user insists on REST, switch to an `external-wallet` admin signer (see `references/api/create-wallet.md`) — they manage the keys.

5. **For SDK V1 wallet code, the canonical quickstarts are `references/wallet-quickstart-{node,react,rest}.md`.** They show the right `wallet.send(addr, "usdc", "1")`, `wallet.balances([...])`, `wallet.stagingFund(10)`, and the wallet locator formats (`email:user@example.com:evm:smart`, `evm:alias:...`).

6. **For verbs on an existing wallet** (transfer, balance, sign message, send transaction, list transfers, add signers), read the matching file in `references/wallet-actions/` — every guide ships both SDK and REST shapes.

7. **The "under construction" `references/server-agent-wallets.md` is not the source of truth.** `references/server-signer.md` is. Always read server-signer first when the user wants an autonomous wallet.

8. **USDXM ≠ USDC. Pick the right one.** `wallet.stagingFund(amount)` mints USDXM (Crossmint's testnet token). USDXM is fine for self-contained Crossmint demos but **no live x402 / MPP / Worldstore endpoint accepts it**. For any flow that touches an external endpoint on staging, fund with **base-sepolia USDC** via [Circle's faucet](https://faucet.circle.com/) — no auth, no captcha, just paste the address. Read `references/funding-staging-wallets.md` for the per-use-case fund decision and the verbatim instruction the agent should give the user.

9. **"What's your wallet?" has ONE canonical first move.** Real session burned 3 round-trips because the agent tried `GET /api/unstable/agents` (different concept — cards stack — needs a client key) and `GET /api/2025-06-09/wallets` (not a list endpoint, requires a locator) before landing on the right call. The right call is the SDK's `wallets.getWallet("evm:alias:${WALLET_ALIAS}", { chain })`, with `WalletNotAvailableError` → fall through to `createWallet` (idempotent on the same alias). The "What's my wallet?" recipe at the top of `assets/recipes-autonomous.md` packages this; run it directly. `WALLET_ALIAS` is saved to `~/.config/crossmint/.env` by `setup.sh` so you don't need to guess.

10. **Prefer `scripts/wallet.sh` and `scripts/x402.sh` over re-deriving Node.** Real session burned a turn because the agent simplified `wallet.balances([…])` to only USDXM and then *fabricated* a `USDC: 0` row. The CLI tools always query the canonical token set and verify USDC against the on-chain contract. Same for x402 — the script handles v1 + v2, header naming, and receipt decoding so the agent doesn't have to remember.

   **Resolve `$SKILL_ROOT` from the cached `.env`** (written by `setup.sh`):
   ```bash
   SKILL_ROOT=$(grep ^SKILL_ROOT "${HOME}/.config/crossmint/.env" 2>/dev/null | cut -d= -f2-)
   # Fallback if absent (older setup, or skill installed without re-running setup):
   if [[ -z "${SKILL_ROOT:-}" || ! -d "${SKILL_ROOT}" ]]; then
     for c in \
       "$(pwd)/.agents/skills/crossmint" \
       "${HOME}/.claude/plugins/cache"/*/skills/crossmint \
       "${HOME}/.agents/skills/crossmint" \
       "${HOME}/.codex/skills/crossmint"; do
       [[ -d "$c" ]] && { SKILL_ROOT="$c"; break; }
     done
   fi
   ```
   Then run `bash "$SKILL_ROOT/scripts/wallet.sh" <cmd>` etc. All seven commands (info, balance, send, transfers, sign, x402 probe, x402 pay) emit pure JSON on stdout — pipe to `jq` freely.

   First call may take 25s if the runtime cache is cold (`setup.sh` pre-warms it; if you're on a config from before that change, the first script invocation pays the install cost once).

   **Only** fall back to writing inline Node when:
   - The user wants something the script doesn't cover (custom EIP-712 domain, contract call with raw calldata, USDXM-specific test, etc.)
   - The script returns a clear error you need to introspect

11. **x402: ALWAYS probe first, never use `wrapFetchWithPayment`.** When the user asks "pay this URL via x402":
   - **Step 1 is always** `curl -si <URL>` to read the 402 body. You cannot know the version (v1 vs v2), network, amount, or recipient until you do. Two real sessions burned 30+ minutes each by skipping this.
   - **`wrapFetchWithPayment` from `@x402/core/client` is gone** in `@x402/core ≥ 2.11.0`. The Crossmint live docs still show it. Use the manual `client.createPaymentPayload()` + `encodePaymentSignatureHeader()` flow in `references/x402.md` — that's the canonical override and it works against current packages.
   - **Register both schemes up front** because endpoints in the wild use both: `client.register("eip155:*", new ExactEvmScheme(signer))` for v2 + `client.registerV1(network, new ExactEvmSchemeV1(signer))` for v1.
   - **Header name depends on version**: `X-PAYMENT` for v1, `PAYMENT-SIGNATURE` for v2. Derive from `paymentPayload.x402Version`.
   - **Re-sign for each retry.** Payment payloads carry an EIP-3009 `validBefore` (~15 min). A stale header → 500 from the facilitator.
   - **HTTP 405 after a successful payment is an endpoint bug, not a payment bug.** Check `x-payment-response` — if `success: true`, the USDC moved; tell the user the payment landed and show the tx hash.

## What this skill is NOT for

- **Inventing endpoints.** If a fact isn't in `references/`, fetch the live docs at `https://docs.crossmint.com/llms.txt` rather than guessing.
- **Holding a credit card in Claude's name.** Cards must be backed by a real human's Visa/Mastercard. The agent can spend USDC from a wallet it controls; it cannot issue a card to itself.
- **Bypassing passkey / OTP / browser-iframe steps.** When the flow needs a human, the agent waits for them.
- **Production calls without a production key.** Don't auto-promote a staging key; require a fresh one and re-run setup with `--env production`.

---

## Output style

- Lead with the **mode** (AUTO / WITH-USER / CODE-GEN) and the next concrete step.
- Show the exact command before running mutations; wait for confirmation.
- Cite the reference file every snippet came from.
- State which environment (staging vs production) any code targets.
- Never echo `$CROSSMINT_API_KEY` or `$CROSSMINT_SIGNER_SECRET` to the conversation — they live in `~/.config/crossmint/.env` so the user never has to re-type them.
