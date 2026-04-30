# List Agents

> List all agents for the authenticated user.

**API scope required**: `agents.read`



## OpenAPI

````yaml get /unstable/agents
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
  /unstable/agents:
    get:
      tags:
        - Agents
      summary: List Agents
      description: |-
        List all agents for the authenticated user.

        **API scope required**: `agents.read`
      operationId: AgentsController-getAgents-2
      parameters:
        - name: X-API-KEY
          in: header
          description: API key required for authentication
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Returns the list of agents
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AgentOutputListResponseDto'
components:
  schemas:
    AgentOutputListResponseDto:
      type: array
      items:
        type: object
        properties:
          agentId:
            type: string
          metadata:
            type: object
            properties:
              name:
                type: string
              imageUrl:
                type: string
                format: uri
              description:
                type: string
            required:
              - name
        required:
          - agentId
          - metadata
        example:
          agentId: 9b3a1c20-1f2c-4f78-9f4d-6c5b8a3a8a01
          metadata:
            name: My Shopping Agent
            imageUrl: https://example.com/agent.png
            description: Buys groceries on my behalf
      example:
        agentId: 9b3a1c20-1f2c-4f78-9f4d-6c5b8a3a8a01
        metadata:
          name: My Shopping Agent
          imageUrl: https://example.com/agent.png
          description: Buys groceries on my behalf

````