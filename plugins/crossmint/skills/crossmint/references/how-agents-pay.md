# How Agents Pay

> Learn why agents need to pay and how they can make payments.

Agents operate across two distinct economies:

* **The traditional web runs on cards**. Amazon, Shopify stores, SaaS checkouts, and most traditional merchants rely on card payments. Users expect familiar properties like card rewards, refunds, and chargebacks.

* **The agentic web runs on stablecoins**. x402 and MPP-gated APIs, micropayments, and machine-to-machine settlement require stablecoins. Cards don’t work here since fees, chargebacks, and merchant account constraints make small or programmatic payments impractical.

Most agents need both so **Crossmint provides cards and stablecoin wallets as first-class primitives.**

## Payment methods need limits

You cannot give an agent unrestricted access to money:

* Credentials can be leaked
* Agents can overspend or behave unexpectedly

An agent with unlimited access is a liability. The goal is not just "agents can pay", it is "agents can pay securely without exposing sensitive data."

Each payment method enforces this differently:

* **Card agentic protocols**. The user’s real card is stored in a PCI-compliant vault. Users create **virtual cards** for agents with limits (amount, merchant, duration), enforced at the network level via Visa VIC and Mastercard Agent Pay. Developers **never** handle sensitive information.

* **Wallet non-custodial delegation**. The user owns the wallet and grants the agent scoped permissions (spend limit, counterparties, time window). Developers and agents never take custody of funds.

## User flows

Every payment method an agent uses is set up through a user flow — a hosted, customizable UI where the user explicitly delegates access. The flows below cover the end to end integration steps for both cards and wallets.

One principle holds across all of them: **the user stays in control.** Every delegation is explicit, scoped, and revocable. Crossmint provides the UI components and signing flows. You wire them into your product.

<Tabs>
  <Tab title="Cards">
    <Steps>
      <Step title="User saves a card">
        Via a Crossmint-hosted secure iframe.
      </Step>

      <Step title="User enrolls the card for agentic use">
        This step links the card to the "agentic" card rails.

        * Happens in a Crossmint component
        * User verifies ownership (e.g. SMS or bank auth)
        * A passkey is created for future approvals
      </Step>

      <Step title="A virtual card is created with limits">
        The developer requests a virtual card with limits (amount, merchant, expiration). A network modal (Visa/Mastercard) appears and the user confirms using their passkey.
      </Step>

      <Step title="Agent spends using the scoped card">
        Each request returns a **new card number**, scoped and single-use. The agent uses it in browser checkout or APIs.
      </Step>
    </Steps>
  </Tab>

  <Tab title="Stablecoin wallets">
    <Steps>
      <Step title="User creates and funds a non-custodial wallet">
        Created via the Crossmint SDK. The user retains ownership — Crossmint and the developer never take custody. Funded by direct transfer or fiat onramp.
      </Step>

      <Step title="User delegates scoped access to the agent">
        The agent gets its own key and is added as a **signer** on the user's wallet, bound to a permission set the user signs off on:

        * **Spend cap** — max amount the agent can move
        * **Allowed counterparties** — addresses or protocols the agent can interact with
        * **Time window** — when the delegation is valid

        Permissions are enforced onchain. The user can revoke at any time.
      </Step>

      <Step title="Agent transacts autonomously within scope">
        The agent signs and submits transactions with its own key — no user prompt per action. Anything outside the delegated scope is rejected at the wallet level.
      </Step>
    </Steps>
  </Tab>
</Tabs>

## How agents actually pay

Once setup is complete, agents can spend. The payment flow depends on *where* they are paying.

| Flow                                                        | Payment method     | How it works                                                                          | Best for                         |
| ----------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------- | -------------------------------- |
| [x402](/agents/payment-flows/x402)                          | Stablecoin         | Agent calls an endpoint, receives `402 Payment Required`, pays in stablecoin, retries | Pay-per-call APIs, micropayments |
| [MPP](/agents/payment-flows/mpp)                            | Stablecoin         | Agent-to-agent and service-to-service payments over a payment protocol                | Programmatic machine economies   |
| [Browser Checkout](/agents/payment-flows/browser-checkout)  | Card               | Agent drives a real browser and fills checkout forms using a virtual card             | Any website that accepts cards   |
| [Fast Checkout](/agents/payment-flows/worldstore/inventory) | Card or stablecoin | A single API call replaces the entire checkout flow — no browser needed               | Amazon, Shopify stores (US only) |

## Choose Your Path

<CardGroup cols={2}>
  <Card title="Cards quickstart" icon="credit-card" href="/agents/cards-quickstart">
    Build an agent paying with virtual cards.
  </Card>

  <Card title="Wallets quickstart" icon="wallet" href="/agents/stablecoin-wallet-quickstart">
    Build an agent paying with stablecoins.
  </Card>
</CardGroup>
