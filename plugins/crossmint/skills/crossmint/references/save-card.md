# Save a Card

> **Missing content — do not use this file.** The source doc at `/docs/5-save-a-card.md` was a byte-identical duplicate of `4-register-an-agent.md`. The real "Save a Card" guide must be fetched from the live docs before the agent can rely on it.

## What this file should cover

The **Save a Card** step of the cards quickstart flow. Comes after `register-agent.md`, before `enroll-card.md`. Covers:

- Mounting Crossmint's PCI-compliant card collection UI (the user types PAN/expiry/CVC inside Crossmint's iframe — your backend never sees raw card data)
- Linking the saved card to the agent created in the previous step
- The `paymentMethodId` returned for use in subsequent enrollment

## Where to find the real content

Fetch live: `https://docs.crossmint.com/agents/payment-methods/cards/save-card` (verify the path against `https://docs.crossmint.com/llms.txt`)

## Until repaired

If the user asks about saving a card, tell them this guide is being repaired and link them to the live doc above. Do **not** invent the API surface.
