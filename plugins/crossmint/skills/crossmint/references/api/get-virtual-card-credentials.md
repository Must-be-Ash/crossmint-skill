# Get Virtual Card Credentials

> Get credentials for an order intent.

**API scope required**: `order-intents.credentials`



## OpenAPI

````yaml post /unstable/order-intents/{orderIntentId}/credentials
openapi: 3.0.0
info:
  title: Crossmint Payments API
  description: Crossmint Payments API
  version: 1.0.0
  contact:
    name: Crossmint Support
    url: https://www.crossmint.com
    email: support@crossmint.com
servers:
  - url: https://staging.crossmint.com/api
    description: Staging environment (testnets)
  - url: https://www.crossmint.com/api
    description: Production environment (mainnets)
security: []
tags: []
paths:
  /unstable/order-intents/{orderIntentId}/credentials:
    post:
      tags:
        - Order Intents
      summary: Get Order Intent Credentials
      description: |-
        Get credentials for an order intent.

        **API scope required**: `order-intents.credentials`
      operationId: OrderIntentsController-getOrderIntentCredentials-2
      parameters:
        - name: X-API-KEY
          in: header
          description: API key required for authentication
          required: true
          schema:
            type: string
        - name: orderIntentId
          required: true
          in: path
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/GetOrderIntentCredentialsBodyDto'
      responses:
        '201':
          description: Returns the order intent credentials
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/OrderIntentCredentialsResponseDto'
components:
  schemas:
    GetOrderIntentCredentialsBodyDto:
      type: object
      properties:
        merchant:
          type: object
          properties:
            name:
              type: string
              minLength: 1
            url:
              type: string
              format: uri
            countryCode:
              type: string
              pattern: ^[A-Z]{2}$
        products:
          minItems: 1
          type: array
          items:
            type: object
            properties:
              name:
                type: string
              price:
                type: number
                minimum: 0
              quantity:
                type: integer
                minimum: 1
                maximum: 9007199254740991
            required:
              - name
              - price
              - quantity
      required:
        - merchant
    OrderIntentCredentialsResponseDto:
      type: object
      properties:
        card:
          type: object
          properties:
            number:
              type: string
            expirationMonth:
              type: string
            expirationYear:
              type: string
            cvc:
              type: string
        expiresAt:
          type: string
      required:
        - card
        - expiresAt

````