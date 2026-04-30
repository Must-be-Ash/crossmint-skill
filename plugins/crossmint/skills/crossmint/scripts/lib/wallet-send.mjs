// wallet-send: send a token via wallet.send(recipient, token, amount).
// Reads RECIPIENT, TOKEN, AMOUNT from env. Echoes the action to stderr before submitting.
// Outputs JSON {hash, explorer, recipient, token, amount, chain} on success.

// Capture and silence everything written to stdout by transitive imports.
// We restore the writer at the end and emit the final JSON only.
const __cmsRealStdoutWrite = process.stdout.write.bind(process.stdout);
process.stdout.write = function (chunk, enc, cb) { return process.stderr.write(chunk, enc, cb); };
const __cmsLog = (...a) => __cmsRealStdoutWrite(a.map(x => typeof x === "string" ? x : JSON.stringify(x)).join(" ") + "\n");
console.log = (...a) => process.stderr.write(a.join(" ") + "\n");

const { createCrossmint, CrossmintWallets } = await import("@crossmint/wallets-sdk");

const apiKey = process.env.CROSSMINT_SERVER_API_KEY || process.env.CROSSMINT_API_KEY;
if (!apiKey) { process.stderr.write("FAIL: no CROSSMINT_SERVER_API_KEY in env\n"); process.exit(1); }

const chain = process.env.CMS_DEFAULT_CHAIN || (process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia");
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";

const recipient = process.env.RECIPIENT;
const token = (process.env.TOKEN || "usdc").toLowerCase();
const amount = process.env.AMOUNT;

if (!recipient || !amount) {
  process.stderr.write("FAIL: RECIPIENT and AMOUNT env vars are required.\n");
  process.stderr.write("       Usage: wallet.sh send <recipient> <token> <amount>\n");
  process.exit(2);
}

const crossmint = createCrossmint({ apiKey });
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain });
await wallet.useSigner({ type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET });

process.stderr.write(`SENDING: ${amount} ${token.toUpperCase()} from ${wallet.address} to ${recipient} on ${chain}\n`);

const tx = await wallet.send(recipient, token, amount);

__cmsLog(JSON.stringify({
  hash: tx.hash,
  explorer: tx.explorerLink,
  from: wallet.address,
  recipient,
  token,
  amount,
  chain,
}, null, 2));
