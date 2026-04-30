# Order Management

> Track order delivery statuses and request order refunds

<Tabs>
  <Tab title="Order Tracking">
    Order tracking only works for Amazon orders right now.

    ## Integration Steps

    <Steps>
      <Step title="Obtain Crossmint API key">
        Create a project in the <a href="https://staging.crossmint.com/signin?callbackUrl=/console" target="_blank">Crossmint Console</a>, obtain a server-side API key from the Overview page, and make sure to save it for later use.
      </Step>

      <Step title="Fetch orderId">
        Obtain the `orderId` from the response of the [Create Order](/api-reference/headless/create-order) endpoint.
      </Step>

      <Step title="Track order">
        <CodeGroup>
          ```bash cURL theme={null}
          curl -X GET "https://staging.crossmint.com/api/unstable/orders/${orderId}/tracking" \
          -H "X-API-KEY: ${API_KEY}" \
          -H "Content-Type: application/json"
          ```

          ```javascript Node.js theme={null}
          const baseUrl = "staging"; // or 'www' for prod environment
          const orderId = "<ORDER_ID>"; // i.e. b2959ca5-65e4-466a-bd26-1bd05cb4f837
          const API_KEY = "<CROSSMINT_API_KEY>" // i.e. sk_staging_5qJURKJ...
          const response = await fetch(`https://${baseUrl}.crossmint.com/api/unstable/orders/${orderId}/tracking`, {
              method: "GET",
              headers: {
                  // API key requires `orders.read` scope.
                  "X-API-KEY": `${API_KEY}`,
                  "Content-Type": "application/json",
              },
          });

          const trackingData = await response.json();
          console.log("Tracking information:", trackingData);
          ```

          ```python Python theme={null}
          import requests

          order_id = "<ORDER_ID>" # i.e. b2959ca5-65e4-466a-bd26-1bd05cb4f837
          base_url = "staging"  # or 'www' for prod environment
          API_KEY = "<CROSSMINT_API_KEY>" # i.e. sk_staging_5qJURKJ...
          response = requests.get(
              f"https://{base_url}.crossmint.com/api/unstable/orders/{order_id}/tracking",
              headers={
                  "X-API-KEY": API_KEY,
                  "Content-Type": "application/json",
              }
          )

          tracking_data = response.json()
          print("Tracking information:", tracking_data)
          ```
        </CodeGroup>

        <Accordion title="Example Response">
          ```json theme={null}
          [
              {
                  "status": "shipped",
                  "packageTracking": {
                      "carrierName": "Amazon",
                      "carrierTrackingNumber": "TBA123456789"
                  },
                  "deliveryTimeRange": {
                      "lowerBound": "2025-08-16T12:28:34.97Z",
                      "upperBound": "2025-08-16T18:28:34.97Z"
                  }
              }
          ]
          ```

          * Status `delivered` is only guaranteed for Amazon packages at the moment.
          * If the package is in `delivered` state, lowerBound is equal to upperBound and it is just the time the package arrived.
        </Accordion>
      </Step>
    </Steps>
  </Tab>

  <Tab title="Order Refunds">
    Crossmint supports requests for refunds. As part of their request they can specify the reason they want a refund. Crossmint will process their request and email them with a shipping label to return the product in order to receive the refund.

    ## Integration Steps

    <Steps>
      <Step title="Obtain Crossmint API key">
        Create a project in the <a href="https://staging.crossmint.com/signin?callbackUrl=/console" target="_blank">Crossmint Console</a>, obtain a server-side API key from the Overview page, and make sure to save it for later use.
      </Step>

      <Step title="Identify product">
        * Fetch an order's products via the [Get Order API](/api-reference/headless/get-order)
        * Identify a specific product via its index in the lineItems array, i.e. 0.
      </Step>

      <Step title="Submit refund request">
        A user can only specify one product per refund request and the reason they are submiting the refund.

        <CodeGroup>
          ```bash cURL theme={null}
          curl -X POST "https://staging.crossmint.com/api/unstable/orders/${orderId}/refunds" \
          -H "X-API-KEY: ${API_KEY}" \
          -H "Content-Type: application/json" \
          -d '{
              "lineItem": 0,
              "reason": "I want to return this product and get a refund as it is defective"
          }'
          ```

          ```javascript Node.js theme={null}
          const baseUrl = "staging"; // or 'www' for prod environment
          const orderId = "<ORDER_ID>"; // i.e. b2959ca5-65e4-466a-bd26-1bd05cb4f837
          const API_KEY = "<CROSSMINT_API_KEY>" // i.e. sk_staging_5qJURKJ...
          const response = await fetch(`https://${baseUrl}.crossmint.com/api/unstable/orders/${orderId}/refunds`, {
              method: "POST",
              headers: {
                  // API key requires `orders.update` scope.
                  "X-API-KEY": `${API_KEY}`,
                  "Content-Type": "application/json",
              },
              body: JSON.stringify({
                  lineItem: 0,
                  reason: "I want to return this product and get a refund as it is defective" // or any relevant reason that applies
              }),
          });

          const refundData = await response.json();
          console.log("Refund request:", refundData);
          ```

          ```python Python theme={null}
          import requests
          import json

          order_id = "<ORDER_ID>" # i.e. b2959ca5-65e4-466a-bd26-1bd05cb4f837
          base_url = "staging"  # or 'www' for prod environment
          API_KEY = "<CROSSMINT_API_KEY>" # i.e. sk_staging_5qJURKJ...
          response = requests.post(
              f"https://{base_url}.crossmint.com/api/unstable/orders/{order_id}/refunds",
              headers={
                  "X-API-KEY": API_KEY,
                  "Content-Type": "application/json",
              },
              data=json.dumps({
                  "lineItem": 0,
                  "reason": "I want to return this product and get a refund as it is defective"  # or any relevant reason that applies
              })
          )

          refund_data = response.json()
          print("Refund request:", refund_data)
          ```
        </CodeGroup>

        <Accordion title="Example Response">
          ```json theme={null}
          {
              "orderId": "order_123456789",
              "lineItem": 0,
              "reason": "I want to return this product and get a refund as it is defective",
              "status": "refund-request-initiated"
          }
          ```
        </Accordion>
      </Step>

      <Step title="Track refund request status">
        Track the `status` value returned from the following endpoint. To fetch a specific product's refund status specify a `lineItem` index value as a query parameter, otherwise fetch them all, by default.

        <CodeGroup>
          ```bash cURL theme={null}
          curl -X GET "https://staging.crossmint.com/api/unstable/orders/${orderId}/refunds" \
          -H "X-API-KEY: ${API_KEY}" \
          -H "Content-Type: application/json"
          ```

          ```javascript Node.js theme={null}
          const baseUrl = "staging"; // or 'www' for prod environment
          const orderId = "<ORDER_ID>"; // i.e. b2959ca5-65e4-466a-bd26-1bd05cb4f837
          const API_KEY = "<CROSSMINT_API_KEY>" // i.e. sk_staging_5qJURKJ...
          const response = await fetch(`https://${baseUrl}.crossmint.com/api/unstable/orders/${orderId}/refunds`, {
              method: "GET",
              headers: {
                  "X-API-KEY": `${API_KEY}`,
                  "Content-Type": "application/json",
              },
          });

          const refundsData = await response.json();
          console.log("Refund requests:", refundsData);
          ```

          ```python Python theme={null}
          import requests

          order_id = "<ORDER_ID>" # i.e. b2959ca5-65e4-466a-bd26-1bd05cb4f837
          base_url = "staging"  # or 'www' for prod environment
          API_KEY = "<CROSSMINT_API_KEY>" # i.e. sk_staging_5qJURKJ...
          response = requests.get(
              f"https://{base_url}.crossmint.com/api/unstable/orders/{order_id}/refunds",
              headers={
                  "X-API-KEY": API_KEY,
                  "Content-Type": "application/json",
              }
          )

          refunds_data = response.json()
          print("Refund requests:", refunds_data)
          ```
        </CodeGroup>

        <Accordion title="Example Response">
          ```json theme={null}
          [
              {
                  "orderId": "order_123456789",
                  "lineItem": 1,
                  "reason": "I want to return this product and get a refund as it is defective",
                  "status": "refund-request-accepted"
              },
              {
                  "orderId": "order_123456789",
                  "lineItem": 2,
                  "reason": "Item arrived damaged",
                  "status": "refund-request-completed"
              }
          ]
          ```

          Potential `status` values:

          * `refund-request-initiated`: Refund request has been submitted
          * `refund-request-accepted`: Refund request has been approved
          * `refund-request-rejected`: Refund request has been denied
          * `refund-request-completed`: Refund has been processed and completed
        </Accordion>
      </Step>

      <Step title="Return product and receive refund">
        Crossmint will send a return shipping label to the email that was used to complete the order when the `status` from Step 4 is `refund-request-accepted`.
        Once the product is successfully returned, the `status` from Step 4 will be set to `refund-request-completed` and the user will receive the refund to the wallet that paid for the order.
      </Step>
    </Steps>
  </Tab>
</Tabs>
