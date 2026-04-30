// wallet-info: get-or-create the default agent wallet, print address + meta as JSON.
// Idempotent — same alias + same secret + same project + same chain → same address.

// Route SDK chatter to stderr; reserve stdout for the JSON result.
// (Done before dynamic-importing the SDK, otherwise SDK logger already booted.)
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

const crossmint = createCrossmint({ apiKey });
const wallets = CrossmintWallets.from(crossmint);

let wallet, created = false;
try {
  wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain });
} catch (e) {
  const msg = e?.message || "";
  if (e?.name === "WalletNotAvailableError" || /not.*found|no.*wallet|404/i.test(msg)) {
    wallet = await wallets.createWallet({
      chain,
      recovery: { type: "server", secret: process.env.CROSSMINT_SIGNER_SECRET },
      alias,
    });
    created = true;
  } else {
    process.stderr.write(`FAIL: getWallet failed: ${msg}\n`);
    process.exit(1);
  }
}

__cmsLog(JSON.stringify({
  address: wallet.address,
  alias,
  chain,
  env: process.env.CROSSMINT_ENV || "staging",
  created,
}, null, 2));
