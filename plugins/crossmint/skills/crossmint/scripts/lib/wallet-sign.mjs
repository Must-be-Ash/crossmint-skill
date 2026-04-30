// wallet-sign: EIP-191 sign a plain message via EVMWallet.signMessage.
// MESSAGE env var required. Prints {message, signature, signer, chain}.

// Capture and silence everything written to stdout by transitive imports.
// We restore the writer at the end and emit the final JSON only.
const __cmsRealStdoutWrite = process.stdout.write.bind(process.stdout);
process.stdout.write = function (chunk, enc, cb) { return process.stderr.write(chunk, enc, cb); };
const __cmsLog = (...a) => __cmsRealStdoutWrite(a.map(x => typeof x === "string" ? x : JSON.stringify(x)).join(" ") + "\n");
console.log = (...a) => process.stderr.write(a.join(" ") + "\n");

const { createCrossmint, CrossmintWallets, EVMWallet } = await import("@crossmint/wallets-sdk");

const apiKey = process.env.CROSSMINT_SERVER_API_KEY || process.env.CROSSMINT_API_KEY;
if (!apiKey) { process.stderr.write("FAIL: no CROSSMINT_SERVER_API_KEY in env\n"); process.exit(1); }

const chain = process.env.CMS_DEFAULT_CHAIN || (process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia");
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";
const message = process.env.MESSAGE;

if (!message) {
  process.stderr.write("FAIL: MESSAGE env var is required.\n       Usage: wallet.sh sign \"<message>\"\n");
  process.exit(2);
}

const crossmint = createCrossmint({ apiKey });
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain });
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });
const evmWallet = EVMWallet.from(wallet);

const result = await evmWallet.signMessage({ message });

__cmsLog(JSON.stringify({
  message,
  signature: result.signature || result,
  signer: wallet.address,
  chain,
}, null, 2));
