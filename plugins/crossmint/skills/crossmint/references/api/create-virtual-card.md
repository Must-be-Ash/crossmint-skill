# Create Virtual Card

> Create a new order intent.

**API scope required**: `order-intents.create`



## OpenAPI

````yaml post /unstable/order-intents
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
  /unstable/order-intents:
    post:
      tags:
        - Order Intents
      summary: Create Order Intent
      description: |-
        Create a new order intent.

        **API scope required**: `order-intents.create`
      operationId: OrderIntentsController-createOrderIntent-2
      parameters:
        - name: X-API-KEY
          in: header
          description: API key required for authentication
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateOrderIntentInputDto'
      responses:
        '201':
          description: The order intent has been successfully created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/OrderIntentOutputResponseDto'
components:
  schemas:
    CreateOrderIntentInputDto:
      type: object
      properties:
        agentId:
          type: string
        payment:
          type: object
          properties:
            paymentMethodId:
              type: string
        mandates:
          type: array
          items:
            oneOf:
              - type: object
                properties:
                  type:
                    type: string
                    enum:
                      - maxAmount
                  value:
                    type: string
                  details:
                    type: object
                    properties:
                      currency:
                        type: string
                        enum:
                          - usd
                          - eur
                          - aud
                          - gbp
                          - jpy
                          - sgd
                          - hkd
                          - krw
                          - inr
                          - vnd
                          - cop
                      period:
                        type: string
                        enum:
                          - weekly
                          - monthly
                          - yearly
                    required:
                      - currency
                required:
                  - type
                  - value
                  - details
              - type: object
                properties:
                  type:
                    type: string
                    enum:
                      - consumer
                  details:
                    type: object
                    properties:
                      email:
                        type: string
                        format: email
                        pattern: >-
                          ^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$
                    required:
                      - email
                required:
                  - type
                  - details
              - type: object
                properties:
                  type:
                    type: string
                    enum:
                      - description
                  value:
                    type: string
                required:
                  - type
                  - value
              - type: object
                properties:
                  type:
                    type: string
                    enum:
                      - prompt
                  value:
                    type: string
                required:
                  - type
                  - value
        expiresAt:
          type: string
          format: date-time
          pattern: >-
            ^(?:(?:\d\d[2468][048]|\d\d[13579][26]|\d\d0[48]|[02468][048]00|[13579][26]00)-02-29|\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\d|30)|(?:02)-(?:0[1-9]|1\d|2[0-8])))T(?:(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:\.\d+)?)?(?:Z))$
      required:
        - agentId
        - payment
        - mandates
    OrderIntentOutputResponseDto:
      oneOf:
        - type: object
          properties:
            orderIntentId:
              type: string
            agentId:
              type: string
            mandates:
              type: array
              items:
                oneOf:
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - maxAmount
                      value:
                        type: string
                      details:
                        type: object
                        properties:
                          currency:
                            type: string
                            enum:
                              - usd
                              - eur
                              - aud
                              - gbp
                              - jpy
                              - sgd
                              - hkd
                              - krw
                              - inr
                              - vnd
                              - cop
                          period:
                            type: string
                            enum:
                              - weekly
                              - monthly
                              - yearly
                        required:
                          - currency
                    required:
                      - type
                      - value
                      - details
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - consumer
                      details:
                        type: object
                        properties:
                          email:
                            type: string
                            format: email
                            pattern: >-
                              ^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$
                        required:
                          - email
                    required:
                      - type
                      - details
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - description
                      value:
                        type: string
                    required:
                      - type
                      - value
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - prompt
                      value:
                        type: string
                    required:
                      - type
                      - value
            payment:
              type: object
              properties:
                paymentMethodId:
                  type: string
              required:
                - paymentMethodId
            phase:
              type: string
              enum:
                - requires-verification
            verificationConfig:
              type: object
              properties:
                environment:
                  type: string
                  enum:
                    - production
                    - test
                publicApiKey:
                  type: string
                agentId:
                  type: string
                instructionId:
                  type: string
              required:
                - environment
                - publicApiKey
                - agentId
                - instructionId
          required:
            - orderIntentId
            - agentId
            - mandates
            - payment
            - phase
            - verificationConfig
        - type: object
          properties:
            orderIntentId:
              type: string
            agentId:
              type: string
            mandates:
              type: array
              items:
                oneOf:
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - maxAmount
                      value:
                        type: string
                      details:
                        type: object
                        properties:
                          currency:
                            type: string
                            enum:
                              - usd
                              - eur
                              - aud
                              - gbp
                              - jpy
                              - sgd
                              - hkd
                              - krw
                              - inr
                              - vnd
                              - cop
                          period:
                            type: string
                            enum:
                              - weekly
                              - monthly
                              - yearly
                        required:
                          - currency
                    required:
                      - type
                      - value
                      - details
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - consumer
                      details:
                        type: object
                        properties:
                          email:
                            type: string
                            format: email
                            pattern: >-
                              ^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$
                        required:
                          - email
                    required:
                      - type
                      - details
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - description
                      value:
                        type: string
                    required:
                      - type
                      - value
                  - type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - prompt
                      value:
                        type: string
                    required:
                      - type
                      - value
            payment:
              type: object
              properties:
                paymentMethodId:
                  type: string
              required:
                - paymentMethodId
            phase:
              type: string
              enum:
                - requires-payment-method
                - active
                - expired
          required:
            - orderIntentId
            - agentId
            - mandates
            - payment
            - phase
      example:
        orderIntentId: oi_8d6a4b1f-9c8a-4cba-b2c1-3a5b8c0d6f12
        agentId: 9b3a1c20-1f2c-4f78-9f4d-6c5b8a3a8a01
        phase: requires-verification
        payment:
          paymentMethodId: pm_8d6a4b1f-9c8a-4cba-b2c1-3a5b8c0d6f12
        mandates:
          - type: maxAmount
            value: '100.00'
            details:
              currency: usd
              period: monthly
          - type: description
            value: Weekly grocery purchases
        verificationConfig:
          environment: production
          publicApiKey: key_publicSomething
          agentId: agt_btxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          instructionId: ins_btxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

````