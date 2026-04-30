# Cards

> Get your agent paying with a virtual card in 15 minutes.

Issue virtual credit cards on behalf of a user with Crossmint's Agentic Payments API. This quickstart runs the [virtual cards reference app](https://github.com/Crossmint/virtual-cards-quickstart).

By the end you'll have a running app where a user can log in, save a real card, authorize an agent, and get back a virtual card — number, expiration, and CVC.

<CardGroup cols={2}>
  <Card title="Try the live demo" icon="rocket" href="https://virtual-cards-quickstart.vercel.app/">
    See the full flow in action without setting anything up locally.
  </Card>

  <Card title="Virtual Cards Quickstart" icon="code" href="https://github.com/Crossmint/virtual-cards-quickstart">
    Explore the full reference implementation for agents, payment methods, and virtual cards.
  </Card>
</CardGroup>

## Prerequisites

* Node.js 20+ and pnpm
* A [Stytch](https://stytch.com) account (used as the auth provider in this example)

<Note>
  **Eligible Cards**

  You can currently create virtual cards only with eligible U.S.-issued Visa credit and debit cards.

  **Not supported:** non-US cards, business cards, prepaid cards, Chase cards, Fidelity cards.

  For Mastercard, AMEX, and Ramp cards, [contact us](https://www.crossmint.com/contact).
</Note>

## Setup

<Steps>
  <Step title="Clone the repo and install dependencies">
    You can ask your agent to walk you through the setup to run this quickstart.

    ```bash theme={null}
    git clone https://github.com/Crossmint/virtual-cards-quickstart.git
    cd virtual-cards-quickstart
    pnpm install
    ```
  </Step>

  <Step title="Configure environment variables">
    Copy the example file and fill in the keys from the previous steps:

    ```bash theme={null}
    cp .env.example .env.local
    ```

    ```bash .env.local theme={null}
    NEXT_PUBLIC_STYTCH_PUBLIC_TOKEN=your-stytch-public-token
    NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY=your-crossmint-client-api-key
    ```
  </Step>

  <Step title="Get a Crossmint staging API key">
    Sign in to the <a href="https://staging.crossmint.com/signin?callbackUrl=/console" target="_blank">Crossmint Staging Console</a> and create a project.

    Staging keys come with **all scopes enabled by default**, so you don't need to configure anything else for the quickstart. Copy the key and paste it into your `.env.local`.
  </Step>

  <Step title="Set up Stytch">
    In the <a href="https://stytch.com/dashboard" target="_blank">Stytch dashboard</a>, in the **Test** environment of a **B2C** project:

    1. **Configuration → SDK Configuration → OAuth** — enable **Google** (Stytch's shared test client works, no Google Cloud setup needed).
    2. **Configuration → Redirect URLs** — add `http://localhost:3000` as both **Login** and **Signup**. Use exactly that, no trailing slash or `/callback`.
    3. **Project Settings → API Keys** — copy the **Public token** (`public-token-test-...`) into `NEXT_PUBLIC_STYTCH_PUBLIC_TOKEN` in your `.env.local`.
  </Step>

  <Step title="Register Stytch as your auth provider in Crossmint">
    In the <a href="https://staging.crossmint.com/console/projects/apiKeys" target="_blank">Crossmint Staging Console</a>, under **3P Auth providers**:

    1. Select **Stytch** from the provider dropdown.
    2. Paste your Stytch **Project ID** (`project-test-...`, found in Stytch under **Project Settings → Project ID**).
    3. Leave **Verifier Id** as `sub` (default).

    Crossmint will start trusting JWTs minted by your Stytch project on subsequent SDK calls.
  </Step>

  <Step title="Run the dev server">
    ```bash theme={null}
    pnpm dev
    ```

    Open [http://localhost:3000](http://localhost:3000).
  </Step>
</Steps>

## Understanding the user flow

Once running, the app walks the user through five steps:

1. **Authenticate.** Sign in with Google via Stytch. The session JWT is bridged into the Crossmint SDK so every API call is scoped to the user.
2. **Register an agent.** Click **Create agent** to get an `agentId` — the handle every virtual card is bound to.
3. **Save a card.** The `CrossmintPaymentMethodManagement` component collects the card in a PCI-compliant iframe and returns a `paymentMethodId`.
4. **Enroll the card for agentic use.** A one-time email code + passkey ceremony links the saved card to the agentic card rails. This is what authorizes agents to issue virtual cards against it — saving alone is not enough.
5. **Issue a virtual card.** An **order intent** is created with two **mandates**: `maxAmount` of 150 USD per `weekly` period and a free-text `description`. The user taps their passkey to authorize the spend, the app fetches credentials with the merchant info, and the virtual card **number, expiration, and CVC** are displayed.

## Next Steps

<CardGroup cols={3}>
  <Card title="Customize UI" icon="palette" href="/agents/payment-methods/cards/customize-verification-ui">
    Style the card and passkey verification modals to match your brand.
  </Card>

  <Card title="Fast Checkout" icon="rocket" href="/agents/payment-flows/worldstore/inventory">
    Replace browser-driving with a single API call for Amazon, Shopify, and more.
  </Card>

  <Card title="Browser Checkout" icon="browser" href="/agents/payment-flows/browser-checkout">
    Have the agent drive a real browser and complete checkout on any site.
  </Card>
</CardGroup>
