# Moving to Production

> Deploy autonomous commercial transactions to production

<Snippet file="enterprise-feature-agentic-commerce.mdx" />

## Moving to Production

Once you've tested your integration in staging, follow these steps to deploy to production:

<Steps>
  <Step title="Create Production Project">
    Create a new project in the <a href="https://www.crossmint.com/signin?callbackUrl=/console" target="_blank">Crossmint Console</a> using the
    **production** environment
  </Step>

  <Step title="Production API Key">
    Generate a production API key with the required scopes: `orders.create`, `orders.ws.search`, `orders.ws.create`,
    `orders.read`, `wallets:transactions.create`
  </Step>

  <Step title="Update Configuration">
    Update your application to use the production API key and production endpoints
  </Step>

  <Step title="Test Production Flow">
    Perform end-to-end testing with real payment methods to ensure everything works correctly
  </Step>
</Steps>
