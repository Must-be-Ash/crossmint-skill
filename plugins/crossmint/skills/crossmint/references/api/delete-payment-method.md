# Delete Payment Method

> Delete a payment method.

**API scope required**: `payment-methods.delete`

<Warning>
  This endpoint requires a JWT from an **external auth provider** (Auth0, Firebase, Stytch, etc.) or a **custom JWT** backed by a JWKS endpoint. Crossmint Auth is not supported.
</Warning>


## OpenAPI

````yaml delete /unstable/payment-methods/{paymentMethodId}
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
  /unstable/payment-methods/{paymentMethodId}:
    delete:
      tags:
        - Payment Methods
      summary: Delete Payment Method
      description: |-
        Delete a payment method.

        **API scope required**: `payment-methods.delete`
      operationId: PaymentMethodsController-deletePaymentMethod-2
      parameters:
        - name: X-API-KEY
          in: header
          description: API key required for authentication
          required: true
          schema:
            type: string
        - name: paymentMethodId
          required: true
          in: path
          schema:
            type: string
      responses:
        '204':
          description: The payment method has been successfully deleted

````