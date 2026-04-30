# Server Signer

> Authorize wallet operations directly from your server using an API key + a master secret. Keys are derived locally — no external network calls during signing — making it the lowest-latency option.

> **Source-of-truth doc.** Fetched from `https://docs.crossmint.com/wallets/guides/signers/server-signer`. The server-side `@crossmint/wallets-sdk` API surface lives here. **Read this BEFORE writing any server-wallet code** — the SDK's `createWallet` shape is `recovery + alias`, NOT `signer + owner`.

## What is a server signer

A server signer is "a secret that gets deterministically mapped into a private key compatible with the underlying blockchain network." You provide a master secret; the SDK derives chain-specific signing keys from it via HKDF-SHA256. A single secret works across every supported chain in your project.

The secret lives at the infrastructure level — treat it like a production credential. Quarterly rotation is recommended.

## Generating the signer secret

The secret must be either:
- 64 hex characters (case-insensitive), or
- the prefixed form `xmsk1_<64-hex-chars>`

The secret stays on your server. Crossmint never receives it.

### Node.js / TypeScript
```typescript
import { randomBytes } from "crypto";

function generateSignerSecret(): string {
  const hex = randomBytes(32).toString("hex");
  return `xmsk1_${hex}`;
}
```

### Python
```python
import secrets

def generate_signer_secret() -> str:
    return f"xmsk1_{secrets.token_hex(32)}"
```

### Shell (openssl)
```bash
echo "CROSSMINT_SIGNER_SECRET=\"xmsk1_$(openssl rand -hex 32)\""
```

### Environment variable
```bash
CROSSMINT_SIGNER_SECRET="xmsk1_b62b473b3ba7d3d72bf7c3a397f1eb61c305a4193ce670dd056686c13d95bbaa"
# the bare 64-hex form (no prefix) is also accepted
```

## Creating a wallet whose root signer is the server

> **Critical:** the SDK uses `recovery: { type: "server", secret }` to set the root signer, not `signer:`. There is **no** `owner:` field for server-only wallets — use `alias:` to address the wallet later.

```typescript
import { CrossmintWallets, createCrossmint } from "@crossmint/wallets-sdk";

const crossmint = createCrossmint({
  apiKey: process.env.CROSSMINT_API_KEY,        // server-side key
});
const crossmintWallets = CrossmintWallets.from(crossmint);

const wallet = await crossmintWallets.createWallet({
  chain: "base-sepolia",                         // or "base" in production
  recovery: {
    type: "server",
    secret: process.env.CROSSMINT_SIGNER_SECRET,
  },
  alias: "my-server-wallet",                     // human-readable handle
});

console.log(wallet.address);                     // 0x...
```

Returned `wallet` is ready to use immediately — the server signer is also the active signer post-creation.

## Retrieving the wallet later

Use the alias-locator format `evm:alias:<your-alias>`. No need to remember the address.

```typescript
const wallet = await crossmintWallets.getWallet(
  "evm:alias:my-server-wallet",
  { chain: "base-sepolia" }
);

// Activate the server signer for this session
await wallet.useSigner({
  type: "server",
  secret: process.env.CROSSMINT_SIGNER_SECRET,
});

// Now wallet.signTypedData(...), wallet.send(...), etc. work.
```

For Solana the locator prefix is `solana:alias:...` (and `chain: "solana"`).

## How key derivation works

The SDK derives chain-specific private keys via HKDF-SHA256 scoped to your project ID, environment, and target chain:

```
key = HKDF-SHA256(
  ikm:  <master secret>,
  salt: "crossmint",
  info: "<projectId>:<environment>:<chain>-<algorithm>"
)
```

The project ID and environment come from your server API key automatically — so the same master secret produces entirely different signing keys per project, per environment, per chain. Compromising one chain's key does not expose the others.

## Server signer locators

When you need to reference the server signer in API calls:

```
server:0x1234567890123456789012345678901234567890
```

The address is the public address derived from your secret for the target chain. The SDK computes it for you whenever you pass `type: "server"`.

## Important limitations

- **Server-signer wallets require the SDK.** You cannot drive them via the REST API directly because the API has no access to the secret (and shouldn't) — the SDK does HKDF derivation and signing locally.
- **If you need raw REST API control,** use an external-wallet signer instead (you manage the keys, you sign, you submit).

## Common gotchas

| Symptom | Likely cause | Fix |
|---|---|---|
| `"recovery is required"` from `createWallet` | Passed `signer:` instead of `recovery:` | Use `recovery: { type: "server", secret }`. The `signer:` field does not exist on `createWallet`. |
| `"owner: invalid format"` | Passed `owner: "agent:foo"` for a server wallet | Server wallets don't take `owner`. Use `alias: "..."` instead. |
| `403` from a wallets call | Using a client-side key (`ck_*`) instead of server-side (`sk_*`) | Server-signer wallets need `sk_*`. |
| Key mismatch between projects | Using the same secret with two different project keys | Expected — the project ID is mixed into HKDF, so each project gets its own derived key. |

## Security

The secret can sign any transaction on every wallet it has been authorized on. Treat it like a production database password:
- Environment variables only, never source control
- Rotate quarterly (or immediately on suspected leak)
- Use a secrets manager / KMS in production, not a flat `.env`
