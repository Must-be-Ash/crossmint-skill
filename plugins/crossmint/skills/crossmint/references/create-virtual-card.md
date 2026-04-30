# Create a Virtual Card

> **Missing content — do not use this file.** The source doc at `/docs/7-create-a-virtual-card.md` was a byte-identical duplicate of `6-enroll-a-card.md`. The real "Create a Virtual Card" guide must be fetched from the live docs before the agent can rely on it.

## What this file should cover

The conceptual flow for issuing a virtual card with spending mandates (amount caps, merchant allow-list, expiry). Comes after `enroll-card.md`, before `using-virtual-cards.md`. The companion API endpoint reference is `api/create-virtual-card.md` (also currently a stub — see that file).

## Where to find the real content

Fetch live: `https://docs.crossmint.com/agents/payment-methods/cards/create-virtual-card` (verify the path against `https://docs.crossmint.com/llms.txt`)

## Until repaired

If the user asks about creating a virtual card, point them at:
- `enroll-card.md` for the prerequisite enrollment ceremony, and
- the live doc URL above for the issuance call itself.

Do **not** fabricate the request shape.
