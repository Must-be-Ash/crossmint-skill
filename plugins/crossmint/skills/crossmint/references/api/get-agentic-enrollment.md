# Get Agentic Enrollment

> Get the agentic enrollment status of a payment method.

**API scope required**: `payment-methods.read`

<Warning>
  This endpoint requires a JWT from an **external auth provider** (Auth0, Firebase, Stytch, etc.) or a **custom JWT** backed by a JWKS endpoint. Crossmint Auth is not supported.
</Warning>


## OpenAPI

````yaml get /unstable/payment-methods/{paymentMethodId}/agentic-enrollment
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
  /unstable/payment-methods/{paymentMethodId}/agentic-enrollment:
    get:
      tags:
        - Payment Methods
      summary: Get Agentic Enrollment
      description: |-
        Get the agentic enrollment status of a payment method.

        **API scope required**: `payment-methods.read`
      operationId: PaymentMethodsController-getAgenticEnrollment-2
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
        '200':
          description: Returns the agentic enrollment status
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AgenticEnrollmentOutputResponseDto'
components:
  schemas:
    AgenticEnrollmentOutputResponseDto:
      oneOf:
        - type: object
          properties:
            enrollmentId:
              type: string
            status:
              type: string
              enum:
                - active
          required:
            - enrollmentId
            - status
        - type: object
          properties:
            enrollmentId:
              type: string
            status:
              type: string
              enum:
                - pending
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
              required:
                - environment
                - publicApiKey
          required:
            - enrollmentId
            - status
            - verificationConfig
      example:
        enrollmentId: enr_8d6a4b1f-9c8a-4cba-b2c1-3a5b8c0d6f12
        status: pending
        verificationConfig:
          environment: production
          publicApiKey: key_publicSomething

````