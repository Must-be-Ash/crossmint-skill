# Create Agent

> Create a new agent.

**API scope required**: `agents.create`



## OpenAPI

````yaml post /unstable/agents
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
    post:
      tags:
        - Agents
      summary: Create Agent
      description: |-
        Create a new agent.

        **API scope required**: `agents.create`
      operationId: AgentsController-createAgent-2
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
              $ref: '#/components/schemas/CreateAgentInputDto'
      responses:
        '201':
          description: The agent has been successfully created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AgentOutputResponseDto'
components:
  schemas:
    CreateAgentInputDto:
      type: object
      properties:
        metadata:
          type: object
          properties:
            name:
              type: string
              minLength: 1
            imageUrl:
              type: string
              format: uri
            description:
              type: string
      required:
        - metadata
    AgentOutputResponseDto:
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
        - agentId
        - metadata

````