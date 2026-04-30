# Browser Checkout

> Pay at any website's checkout using a virtual card and a browser-automation agent.

Virtual cards work anywhere cards are accepted. When your agent needs to buy from a website that doesn't have an API, it can drive a real browser session and fill in the checkout form with virtual card credentials.

This guide explains the end-to-end flow: saving a card, issuing a scoped virtual card, and using a browser automation tool like <a href="https://docs.stagehand.dev/" target="_blank">Stagehand</a> or <a href="https://browser-use.com/" target="_blank">Browser Use</a> to complete the purchase.

<Info>For supported merchants (Amazon, Shopify stores, US only), use [Fast Checkout](/agents/payment-flows/worldstore/inventory) instead — it's a single API call with no browser needed.</Info>

## How it works

The key idea: **the agent never sees the user's real card.** It receives a scoped virtual card — limited by amount, merchant, and duration — that it uses to pay. If the card is compromised or the agent misbehaves, the blast radius is contained.

## Prerequisites

* A saved and enrolled card. See the [Cards setup guide](/agents/cards-quickstart).
* An active virtual card (order intent). See [Create a Virtual Card](/agents/payment-methods/cards/create-virtual-card).
* A browser automation tool: <a href="https://docs.stagehand.dev/" target="_blank">Stagehand</a> or <a href="https://browser-use.com/" target="_blank">Browser Use</a>.

## Steps

<Steps>
  <Step title="Save a card and create a virtual card">
    The user saves their card via Crossmint's PCI-compliant UI. The card is enrolled for agentic use, and a virtual card is issued with spending mandates (amount, merchant, duration). The user approves via passkey.

    For the full setup, see:

    1. [Save a Card](/agents/payment-methods/cards/save-card)
    2. [Enroll a Card](/agents/payment-methods/cards/enroll-card)
    3. [Create a Virtual Card](/agents/payment-methods/cards/create-virtual-card)
  </Step>

  <Step title="Retrieve virtual card credentials">
    When the agent is ready to make a purchase, it fetches the virtual card credentials scoped to the specific merchant:

    ```typescript theme={null}
    const BASE_URL = "https://staging.crossmint.com/api/unstable";

    const response = await fetch(
        `${BASE_URL}/order-intents/${orderIntentId}/credentials`,
        {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-API-KEY": CROSSMINT_API_KEY,
                Authorization: `Bearer ${jwt}`,
            },
            body: JSON.stringify({
                merchant: {
                    name: "Example Store",
                    url: "https://www.example-store.com",
                    countryCode: "US",
                },
            }),
        }
    );

    const { card } = await response.json();
    // card.number, card.expirationMonth, card.expirationYear, card.cvc
    ```

    Each credential fetch returns a fresh, merchant-scoped card number. If leaked, it can't be reused at a different merchant.

    See [Retrieve Virtual Card Credentials](/agents/payment-methods/cards/retrieve-virtual-card) for the full API reference.
  </Step>

  <Step title="Navigate the checkout with a browser automation tool">
    There are several ways to drive a checkout session, and the right one depends on your use case — direct DOM control, LLM-driven autonomous browsing, or your own framework. **In every case the integration with Crossmint is the same:** you fetch a fresh, merchant-scoped virtual card with the snippet above and feed those credentials into whichever tool runs the browser.

    <CodeGroup>
      ```typescript Stagehand theme={null}
      import { Stagehand } from "@browserbasehq/stagehand";

      const stagehand = new Stagehand({ env: "BROWSERBASE" });
      await stagehand.init();

      const page = stagehand.page;
      await page.goto("https://www.example-store.com/checkout");

      await page.act(`Fill in the checkout form with:
      - Card number: ${card.number}
      - Expiration: ${card.expirationMonth}/${card.expirationYear}
      - CVC: ${card.cvc}`);

      await page.act("Submit the order");
      await page.observe("Wait for the order confirmation page");

      await stagehand.close();
      ```

      ```python Browser Use theme={null}
      from browser_use import Agent
      from langchain_openai import ChatOpenAI

      agent = Agent(
          task=f"""Go to https://www.example-store.com/checkout and complete the purchase.
          Use these card details:
          - Card number: {card_number}
          - Expiration: {exp_month}/{exp_year}
          - CVC: {cvc}""",
          llm=ChatOpenAI(model="gpt-5.5"),
      )

      result = await agent.run()
      ```
    </CodeGroup>
  </Step>
</Steps>

## When to use Browser Checkout vs Fast Checkout

|                        | Browser Checkout                                    | Fast Checkout                                         |
| ---------------------- | --------------------------------------------------- | ----------------------------------------------------- |
| **Coverage**           | Any website that accepts cards                      | Amazon, Shopify stores (US only)                      |
| **How it works**       | Agent drives a real browser session                 | Single API call, no browser needed                    |
| **Latency**            | Higher — page loads, form filling, CAPTCHA handling | Lower — direct API                                    |
| **Reliability**        | Can break when sites change their DOM               | Stable API contract                                   |
| **Stablecoin support** | No — cards only                                     | Yes — can pay with stablecoins on card-only merchants |

**Use Browser Checkout** when the merchant isn't supported by Fast Checkout — it works anywhere a card is accepted.

**Use [Fast Checkout](/agents/payment-flows/worldstore/inventory)** when the merchant is supported — it's faster, more reliable, and supports stablecoin payments.

## Learn more

<CardGroup cols={2}>
  <Card title="Cards setup" icon="credit-card" href="/agents/cards-quickstart">
    Full card delegation flow: save, enroll, issue, and retrieve.
  </Card>

  <Card title="Cards quickstart" icon="rocket" href="/agents/cards-quickstart">
    End-to-end quickstart for virtual cards.
  </Card>

  <Card title="Fast Checkout" icon="bolt" href="/agents/payment-flows/worldstore/inventory">
    Skip the browser entirely for supported merchants.
  </Card>

  <Card title="How Agents Pay" icon="book" href="/agents/how-agents-pay">
    The full mental model for agent payments.
  </Card>
</CardGroup>
