// x402-pay: probe + sign + retry. Supports both v1 and v2 schemes.
// Reads URL, optional MAX_AMOUNT (raw USDC) from env.
// Outputs {paidStatus, paidBody, receipt, paymentRequired} to stdout.

const __cmsRealStdoutWrite = process.stdout.write.bind(process.stdout);
process.stdout.write = function (chunk, enc, cb) { return process.stderr.write(chunk, enc, cb); };
const __cmsLog = (...a) => __cmsRealStdoutWrite(a.map(x => typeof x === "string" ? x : JSON.stringify(x)).join(" ") + "\n");
console.log = (...a) => process.stderr.write(a.join(" ") + "\n");

const { createCrossmint, CrossmintWallets, EVMWallet } = await import("@crossmint/wallets-sdk");
const { x402Client }                = await import("@x402/core/client");
const { encodePaymentSignatureHeader } = await import("@x402/core/http");
const { ExactEvmSchemeV1 }          = await import("@x402/evm/exact/v1/client");
const { ExactEvmScheme }            = await import("@x402/evm/exact/client");

const url = process.env.URL;
const maxAmount = process.env.MAX_AMOUNT ? BigInt(process.env.MAX_AMOUNT) : null;
const apiKey = process.env.CROSSMINT_SERVER_API_KEY || process.env.CROSSMINT_API_KEY;
const chainName = process.env.CMS_DEFAULT_CHAIN || (process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia");
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";

if (!url) { process.stderr.write("FAIL: URL env var required\n"); process.exit(2); }
if (!apiKey) { process.stderr.write("FAIL: no CROSSMINT_SERVER_API_KEY in env\n"); process.exit(1); }

// 1. Probe
const probe = await fetch(url, { method: "GET" });
if (probe.status !== 402) {
  __cmsLog(JSON.stringify({
    alreadyPaid: false,
    paidStatus: probe.status,
    paidBody: await probe.text(),
    receipt: null,
    paymentRequired: null,
  }, null, 2));
  process.exit(0);
}
const paymentRequired = await probe.json();
const accept = paymentRequired.accepts?.[0] || {};

// 2. Validate max
if (maxAmount !== null && BigInt(accept.maxAmountRequired || "0") > maxAmount) {
  process.stderr.write(`FAIL: endpoint asks ${accept.maxAmountRequired} raw USDC; --max ${maxAmount} exceeded.\n`);
  process.exit(3);
}

// 3. Network sanity check (warn, don't fail — facilitator will reject if truly mismatched)
const v2Network = chainName === "base" ? "eip155:8453" : "eip155:84532";
if (accept.network && accept.network !== chainName && accept.network !== v2Network) {
  process.stderr.write(`WARN: endpoint network=${accept.network}, wallet chain=${chainName}. Facilitator may reject.\n`);
}

// 4. Wallet + signer
const crossmint = createCrossmint({ apiKey });
const wallets = CrossmintWallets.from(crossmint);
const wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain: chainName });
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });
const evmWallet = EVMWallet.from(wallet);

const x402Signer = {
  address: evmWallet.address,
  async signTypedData(typedData) {
    const { signature } = await evmWallet.signTypedData({ ...typedData, chain: chainName });
    return signature;
  },
};

// 5. Register both schemes
const client = new x402Client();
client.register("eip155:*", new ExactEvmScheme(x402Signer));
client.registerV1(chainName, new ExactEvmSchemeV1(x402Signer));

// 6. Sign payment payload
const paymentPayload = await client.createPaymentPayload(paymentRequired);
const headerValue = encodePaymentSignatureHeader(paymentPayload);
const headerName = paymentPayload.x402Version === 1 ? "X-PAYMENT" : "PAYMENT-SIGNATURE";

process.stderr.write(`PAYING: up to ${accept.maxAmountRequired} raw USDC on ${accept.network} via ${headerName} (x402 v${paymentPayload.x402Version})\n`);

// 7. Retry with payment header
const paid = await fetch(url, { method: "GET", headers: { [headerName]: headerValue } });
const paidBody = await paid.text();
const receiptB64 = paid.headers.get("x-payment-response");
const receipt = receiptB64 ? JSON.parse(Buffer.from(receiptB64, "base64").toString()) : null;

__cmsLog(JSON.stringify({
  paidStatus: paid.status,
  paidBody,
  receipt,
  paymentRequired,
  payer: evmWallet.address,
  chain: chainName,
}, null, 2));
