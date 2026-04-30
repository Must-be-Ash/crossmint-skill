# Create Virtual Card (API)

> **Missing content — do not use this file.** The source doc at `/docs/32-create-virtual-card.md` was a byte-identical duplicate of `31-get-virtual-card.md`. The real POST endpoint reference must be fetched from the live docs before the agent can rely on it.

## What this file should cover

The `POST` endpoint that issues a new virtual card (order intent) for an authorized agent. Required scope, request body shape (amount caps, merchant allow-list, currency, expiry), response shape (`orderIntentId`, status), and an example curl.

The companion endpoints in this folder use `order-intents.read` scope and follow these conventions:
- `api/get-virtual-card.md` — GET by id
- `api/list-virtual-cards.md` — GET list
- `api/get-virtual-card-credentials.md` — GET PAN/expiry/CVC

The POST counterpart should follow the same conventions (`order-intents.create` scope, JSON body, returns the created order intent).

## Where to find the real content

Fetch live from the Crossmint API reference for "Create Virtual Card" (POST). Discover the canonical URL via `https://docs.crossmint.com/llms.txt`.

## Until repaired

Do **not** fabricate request fields. Tell the user this endpoint reference is being repaired and that docs.crossmint.com is the source of truth.
