# Stablecoin Wallets

> Get your agent paying with stablecoins in 10 minutes.

export const SignerSecretGenerator = () => {
  const [secret, setSecret] = useState("");
  const [copied, setCopied] = useState(false);
  const bytesToHex = bytes => {
    return Array.from(bytes).map(b => b.toString(16).padStart(2, "0")).join("");
  };
  const generate = () => {
    const bytes = crypto.getRandomValues(new Uint8Array(32));
    const hex = bytesToHex(bytes);
    setSecret(`xmsk1_${hex}`);
  };
  const envLine = secret ? `CROSSMINT_SIGNER_SECRET="${secret}"` : "";
  const handleCopy = async text => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch (_err) {}
  };
  return <div className="not-prose my-8 rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-6 shadow-lg">
            {}
            <div className="mb-6 flex items-center justify-between gap-2 flex-wrap">
                <div className="flex items-center gap-3">
                    <svg width="28" height="28" viewBox="0 0 100 100" fill="none">
                        <defs>
                            <linearGradient id="markGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                                <stop offset="0%" stopColor="#5EDD4D" />
                                <stop offset="100%" stopColor="#05CE6C" />
                            </linearGradient>
                        </defs>
                        <path d="M50 0C50 27.6 27.6 50 0 50C27.6 50 50 72.4 50 100C50 72.4 72.4 50 100 50C72.4 50 50 27.6 50 0Z" fill="url(#markGrad)" />
                    </svg>
                    <div>
                        <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100 m-0">
                            Signer Secret Generator
                        </h3>
                        <p className="text-xs text-zinc-500 dark:text-zinc-400 m-0 mt-0.5">
                            Generate a master secret for your signing environment
                        </p>
                    </div>
                </div>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 text-green-700 dark:text-green-400 text-xs font-medium">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <rect x="3" y="11" width="18" height="11" rx="2" />
                        <path d="M7 11V7a5 5 0 0110 0v4" />
                    </svg>
                    Client-side only
                </span>
            </div>

            {}
            <div className="mb-5">
                <div className="rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800/50 p-3">
                    <div className="flex gap-2">
                        <input type="text" value={secret} onChange={e => setSecret(e.target.value)} placeholder="xmsk1_a3f8...c7b2" spellCheck={false} className="flex-1 min-w-0 px-3 py-2 text-sm font-mono bg-white dark:bg-zinc-900 border border-zinc-300 dark:border-zinc-600 rounded-lg text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 dark:placeholder-zinc-500 focus:outline-none focus:ring-2 focus:ring-green-500" />
                        <button type="button" onClick={generate} className="inline-flex items-center gap-1.5 px-4 py-2 bg-green-500 hover:bg-green-600 text-white text-sm font-semibold rounded-lg transition-colors whitespace-nowrap">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <polyline points="23 4 23 10 17 10" />
                                <path d="M20.49 15a9 9 0 11-2.12-9.36L23 10" />
                            </svg>
                            Generate
                        </button>
                    </div>
                </div>
            </div>

            {}
            {secret && <div className="mb-5">
                    <div className="text-xs font-semibold text-zinc-500 dark:text-zinc-400 mb-2">
                        Your environment variable
                    </div>
                    <div className="flex items-center gap-2 rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800/50 px-3 py-2.5">
                        <code className="flex-1 min-w-0 text-xs font-mono text-zinc-700 dark:text-zinc-300 overflow-hidden text-ellipsis whitespace-nowrap">
                            {envLine}
                        </code>
                        <button type="button" onClick={() => handleCopy(envLine)} className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium transition-colors whitespace-nowrap ${copied ? "bg-green-100 dark:bg-green-900/30 border border-green-300 dark:border-green-700 text-green-700 dark:text-green-400" : "bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 text-green-600 dark:text-green-400 hover:bg-green-100 dark:hover:bg-green-900/40"}`}>
                            {copied ? <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <polyline points="20 6 9 17 4 12" />
                                </svg> : <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <rect x="9" y="9" width="13" height="13" rx="2" />
                                    <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" />
                                </svg>}
                            {copied ? "Copied!" : "Copy"}
                        </button>
                    </div>
                </div>}
        </div>;
};

Create a user-owned smart wallet, authorize an agent as a delegated signer, and send USDXM on Base Sepolia. This quickstart runs the [stablecoin wallet reference app](https://github.com/Crossmint/stablecoin-wallet-quickstart).

By the end you'll have a running app where a user can sign in, get a non-custodial wallet, authorize an agent with a one-time email code, and watch the agent send a stablecoin transfer signed entirely on your backend — no user prompt per transaction.

<CardGroup cols={2}>
  <Card title="Try the live demo" icon="rocket" href="https://stablecoin-wallet-quickstart.vercel.app/">
    See the full flow in action without setting anything up locally.
  </Card>

  <Card title="Stablecoin Wallet Quickstart" icon="code" href="https://github.com/Crossmint/stablecoin-wallet-quickstart">
    Explore the full reference implementation for user wallets, server signers, and USDXM transfers.
  </Card>
</CardGroup>

## Prerequisites

* Node.js 20+ and pnpm

## Setup

<Steps>
  <Step title="Clone the repo and install dependencies">
    You can ask your agent to walk you through the setup to run this quickstart.

    ```bash theme={null}
    git clone https://github.com/Crossmint/stablecoin-wallet-quickstart.git
    cd stablecoin-wallet-quickstart
    pnpm install
    ```
  </Step>

  <Step title="Configure environment variables">
    Copy the example file. You'll fill in the values in the next steps.

    ```bash theme={null}
    cp .env.example .env.local
    ```

    ```bash .env.local theme={null}
    NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY=your-crossmint-client-api-key
    CROSSMINT_SERVER_SIDE_API_KEY=your-crossmint-server-api-key
    CROSSMINT_SIGNER_SECRET=your-64-char-hex-secret
    ```
  </Step>

  <Step title="Get Crossmint staging API keys">
    Sign in to the <a href="https://staging.crossmint.com/signin?callbackUrl=/console" target="_blank">Crossmint Staging Console</a> and create a project. Then in **Project Settings → API keys**, create:

    1. A **client-side** key → paste into `NEXT_PUBLIC_CROSSMINT_CLIENT_API_KEY`.
    2. A **server-side** key → paste into `CROSSMINT_SERVER_SIDE_API_KEY`.

    Staging keys come with **all scopes enabled by default**, so you don't need to configure anything else for the quickstart.
  </Step>

  <Step title="Generate a signer secret">
    The agent's server signer uses a 32-byte secret that never leaves your backend. Generate one and paste it into `CROSSMINT_SIGNER_SECRET`. Both raw 64-char hex and the prefixed `xmsk1_<64-hex>` format are accepted.

    <SignerSecretGenerator />

    <Warning>
      Anyone who holds this secret can sign on behalf of the wallets it has been authorized on. Store it only as a server-side environment variable; never commit it or ship it to the browser.
    </Warning>
  </Step>

  <Step title="Run the dev server">
    ```bash theme={null}
    pnpm dev
    ```

    Open [http://localhost:3000](http://localhost:3000).
  </Step>
</Steps>

## Understanding the user flow

Once running, the app walks the user through four steps on Base Sepolia:

1. **Authenticate.** Sign in with email OTP or Google via `CrossmintAuthProvider`. Crossmint issues a user JWT that scopes every subsequent SDK call to the signed-in user.
2. **Get a wallet.** `CrossmintWalletProvider` is configured with `createOnLogin={{ chain: "base-sepolia", recovery: { type: "email" } }}`, so a non-custodial smart wallet is created on first login with the user's email as the recovery signer. The address appears as soon as `useWallet()` resolves.
3. **Authorize the agent.** Clicking **Authorize your agent** calls `wallet.addSigner({ type: "server", secret }, { prepareOnly: true })` from your backend, then the user approves the pending registration with a one-time email code. From here on, the server signer can sign for the wallet without any user prompt.
4. **Fund and send.** `wallet.stagingFund(5)` mints 5 USDXM into the wallet (staging-only). A server action then activates the server signer with `wallet.useSigner({ type: "server", secret })` and calls `wallet.send(recipient, "usdxm", amount)` — signed entirely on your backend. This is how an agent spends from a user's wallet in production.

Toggle **Show code** in the header to view the relevant SDK snippet alongside each step.

## Next Steps

<CardGroup cols={3}>
  <Card title="Using the Wallet" icon="paper-plane" href="/agents/payment-methods/stablecoin-wallets/on-chain-actions">
    Send stablecoins, swap, bridge, and call any contract from your agent.
  </Card>

  <Card title="x402" icon="bolt" href="/agents/payment-flows/x402">
    HTTP-native micropayments — pay-per-call APIs and machine-to-machine settlement.
  </Card>

  <Card title="Remove Agent Access" icon="user-xmark" href="/agents/payment-methods/stablecoin-wallets/remove-agent-access">
    Revoke an agent's signer from a user's wallet.
  </Card>
</CardGroup>
