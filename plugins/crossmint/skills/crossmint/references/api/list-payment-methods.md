# List Payment Methods

> List all payment methods for the authenticated user.

**API scope required**: `payment-methods.read`

<Warning>
  This endpoint requires a JWT from an **external auth provider** (Auth0, Firebase, Stytch, etc.) or a **custom JWT** backed by a JWKS endpoint. Crossmint Auth is not supported.
</Warning>


## OpenAPI

````yaml get /unstable/payment-methods
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
  /unstable/payment-methods:
    get:
      tags:
        - Payment Methods
      summary: List Payment Methods
      description: |-
        List all payment methods for the authenticated user.

        **API scope required**: `payment-methods.read`
      operationId: PaymentMethodsController-getPaymentMethods-2
      parameters:
        - name: X-API-KEY
          in: header
          description: API key required for authentication
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Returns the list of payment methods
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserPaymentMethodOutputListResponseDto'
components:
  schemas:
    UserPaymentMethodOutputListResponseDto:
      type: array
      items:
        type: object
        properties:
          type:
            type: string
            enum:
              - card
          paymentMethodId:
            type: string
          default:
            type: boolean
          display:
            type: object
            properties:
              imageUrl:
                type: string
                format: uri
          card:
            type: object
            properties:
              source:
                type: object
                properties:
                  type:
                    type: string
                    enum:
                      - basis-theory-token
                  id:
                    type: string
                  networkTokenId:
                    type: string
                required:
                  - type
                  - id
              brand:
                type: string
                enum:
                  - visa
                  - mastercard
                  - amex
                  - discover
                  - jcb
                  - unionpay
                  - diners-club
              last4:
                type: string
              expiration:
                type: object
                properties:
                  month:
                    type: string
                  year:
                    type: string
                required:
                  - month
                  - year
              billing:
                type: object
                properties:
                  name:
                    type: string
                  address:
                    type: object
                    properties:
                      line1:
                        type: string
                        minLength: 1
                        maxLength: 200
                      line2:
                        type: string
                        maxLength: 60
                      city:
                        type: string
                        minLength: 1
                        maxLength: 50
                      stateOrRegion:
                        type: string
                        maxLength: 50
                      postalCode:
                        type: string
                        minLength: 1
                        maxLength: 20
                      country:
                        type: string
                        minLength: 2
                        maxLength: 2
                    required:
                      - line1
                      - city
                      - postalCode
                      - country
                  phone:
                    type: string
                required:
                  - name
              fundingType:
                type: string
                enum:
                  - credit
                  - debit
                  - prepaid
                  - unknown
              bin:
                type: string
            required:
              - source
              - brand
              - last4
              - expiration
              - billing
        required:
          - type
          - paymentMethodId
          - card
        example:
          type: card
          paymentMethodId: pm_8d6a4b1f-9c8a-4cba-b2c1-3a5b8c0d6f12
          default: true
          display:
            imageUrl: https://example.com/card-art.png
          card:
            source:
              type: basis-theory-token
              id: 01GZ1S0F2K3M4N5P6Q7R8S9T0V
            brand: visa
            last4: '4242'
            expiration:
              month: '12'
              year: '2030'
            billing:
              name: Jane Doe
            fundingType: credit
            bin: '424242'
      example:
        type: card
        paymentMethodId: pm_8d6a4b1f-9c8a-4cba-b2c1-3a5b8c0d6f12
        default: true
        display:
          imageUrl: https://example.com/card-art.png
        card:
          source:
            type: basis-theory-token
            id: 01GZ1S0F2K3M4N5P6Q7R8S9T0V
          brand: visa
          last4: '4242'
          expiration:
            month: '12'
            year: '2030'
          billing:
            name: Jane Doe
          fundingType: credit
          bin: '424242'

````