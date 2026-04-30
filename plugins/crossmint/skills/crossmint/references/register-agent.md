# Register an Agent

> Authenticate a user and create an agent identity for the cards flow.

This guide covers the first two steps of the cards flow: authenticating a user to obtain a JWT, then registering an **agent** that can issue virtual cards on their behalf. By the end you will have an `agentId` to use in every subsequent step.

## Prerequisites

* **Crossmint API key** — a client-side key from the <a href="https://staging.crossmint.com/console/projects/apiKeys" target="_blank">Crossmint Console</a>. In staging, all scopes are enabled by default.
* **Authentication provider** — any provider that issues JWTs your backend can verify (for example <a href="https://stytch.com/" target="_blank">Stytch</a>, Auth0, Dynamic, or [Crossmint Auth](/authentication/introduction)). The <a href="https://github.com/Crossmint/virtual-cards-quickstart" target="_blank">virtual-cards-quickstart</a> uses Stytch with Google OAuth.

## Step 1: Authenticate the User

Before calling any Crossmint endpoint you need a valid session JWT for the user. How you obtain it depends on your auth provider. Below is the pattern used by the quickstart with Stytch:

```typescript theme={null}
import { useStytch } from "@stytch/nextjs";
import { useCrossmint } from "@crossmint/client-sdk-react-ui";

function useAuthSetup() {
    const stytch = useStytch();
    const { setJwt } = useCrossmint();

    // After the user completes login (e.g. Google OAuth redirect):
    const tokens = stytch.session.getTokens();
    const jwt = tokens?.session_jwt ?? "";

    // Bridge the JWT to the Crossmint SDK so it can authenticate requests
    setJwt(jwt);

    return jwt;
}
```

The key requirement is that every Crossmint API call includes:

* `X-API-KEY` header with your Crossmint client API key
* `Authorization: Bearer <jwt>` header with the user's session JWT

If you are using a different auth provider, replace the Stytch calls above with your provider's equivalent. See [Identity and Auth](/authentication/introduction) for more options.

## Step 2: Register an Agent

With the JWT in hand, send a `POST` request to `/api/unstable/agents` to create an agent for this user.

```typescript theme={null}
const BASE_URL = "https://staging.crossmint.com/api/unstable";

const response = await fetch(`${BASE_URL}/agents`, {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        "X-API-KEY": CROSSMINT_API_KEY,
        Authorization: `Bearer ${jwt}`,
    },
    body: JSON.stringify({
        metadata: {
            name: "Virtual Card Agent",
            description: "Default agent for virtual card issuance",
        },
    }),
});

const agent = await response.json();
console.log(agent.agentId); // e.g. "d290f1ee-6c54-4b01-90e6-d701748f0851"
```

Store the `agentId` — you will pass it when saving cards, creating order intents, and fetching virtual card credentials. You typically create **one agent per user**.

For the full request and response schema, see the [Create Agent API Reference](/api-reference/agentic-commerce/agents/create-agent).

<AccordionGroup>
  <Accordion title="Example Response">
    ```json theme={null}
    {
      "agentId": "d290f1ee-6c54-4b01-90e6-d701748f0851",
      "metadata": {
        "name": "Virtual Card Agent",
        "description": "Default agent for virtual card issuance"
      }
    }
    ```
  </Accordion>
</AccordionGroup>

## What Is Next

Now that you have an authenticated user and a registered agent, the next step is to [Save a Card](/agents/payment-methods/cards/save-card) so the agent can use it to issue virtual cards.
