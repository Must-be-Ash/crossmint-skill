# Server Agent Wallets

> Backend-only wallets for autonomous agents with no end user.

## Introduction

A **server agent wallet** is a wallet whose root signer is your backend, not an end user. Use it when there is no human in the loop — autonomous market makers, scheduled task runners, treasury bots, or any agent that operates entirely on its own keys.

This is the opposite end of the trust spectrum from the user-authorized flow. There is no recovery signer to delegate to and no user OTP step. Your backend creates the wallet, signs every transaction, and is fully responsible for the secret.

## Prerequisites

* A Crossmint **server-side** API key from the <a href="https://staging.crossmint.com/console/projects/apiKeys" target="_blank">Crossmint Console</a>.
* A secure secret store for the signer key (environment variable, KMS, or hardware-backed vault). The user-authorized flow has the user as a fallback if the server is compromised — this flow does not.

<Note>This page is under construction. Full content — including signer key management patterns, multi-tenant isolation, and the canonical [server signer reference](/wallets/guides/signers/server-signer) — is coming soon.</Note>

## What Is Next

<CardGroup cols={2}>
  <Card title="Server Signer Deep Dive" icon="server" href="/wallets/guides/signers/server-signer">
    Full reference for the server signer, secret rotation, and key management.
  </Card>

  <Card title="On-Chain Actions" icon="paper-plane" href="/agents/payment-methods/stablecoin-wallets/on-chain-actions">
    Once the wallet is set up, drive it the same way as a user-authorized wallet.
  </Card>
</CardGroup>
