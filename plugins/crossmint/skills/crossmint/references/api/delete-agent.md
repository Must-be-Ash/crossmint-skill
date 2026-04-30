# Delete Agent

> Delete an agent.

**API scope required**: `agents.delete`



## OpenAPI

````yaml delete /unstable/agents/{agentId}
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
  /unstable/agents/{agentId}:
    delete:
      tags:
        - Agents
      summary: Delete Agent
      description: |-
        Delete an agent.

        **API scope required**: `agents.delete`
      operationId: AgentsController-deleteAgent-2
      parameters:
        - name: X-API-KEY
          in: header
          description: API key required for authentication
          required: true
          schema:
            type: string
        - name: agentId
          required: true
          in: path
          schema:
            type: string
      responses:
        '204':
          description: The agent has been successfully deleted

````