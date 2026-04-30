// wallet-transfers: list recent transfers (in + out).
// Tries SDK first; falls back to REST if SDK doesn't expose .transfers().
// LIMIT env var (default 10).

// Capture and silence everything written to stdout by transitive imports.
// We restore the writer at the end and emit the final JSON only.
const __cmsRealStdoutWrite = process.stdout.write.bind(process.stdout);
process.stdout.write = function (chunk, enc, cb) { return process.stderr.write(chunk, enc, cb); };
const __cmsLog = (...a) => __cmsRealStdoutWrite(a.map(x => typeof x === "string" ? x : JSON.stringify(x)).join(" ") + "\n");
console.log = (...a) => process.stderr.write(a.join(" ") + "\n");

const { createCrossmint, CrossmintWallets } = await import("@crossmint/wallets-sdk");

const apiKey = process.env.CROSSMINT_SERVER_API_KEY || process.env.CROSSMINT_API_KEY;
const apiHost = process.env.CROSSMINT_API_HOST || (process.env.CROSSMINT_ENV === "production" ? "https://www.crossmint.com" : "https://staging.crossmint.com");
if (!apiKey) { process.stderr.write("FAIL: no CROSSMINT_SERVER_API_KEY in env\n"); process.exit(1); }

const chain = process.env.CMS_DEFAULT_CHAIN || (process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia");
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";
const limit = parseInt(process.env.LIMIT || "10", 10);
const tokens = process.env.TOKENS || "usdc";  // REST endpoint requires this; default to USDC
const status = process.env.STATUS || "successful";  // REST also requires status; default to successful

const crossmint = createCrossmint({ apiKey });
const wallets = CrossmintWallets.from(crossmint);

const wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain });

let transfers = null, source = null;

if (typeof wallet.transfers === "function") {
  try {
    const r = await wallet.transfers({ limit, tokens });
    transfers = Array.isArray(r) ? r : (r?.data || []);
    source = "sdk";
  } catch (_) { /* fall through */ }
}

if (transfers === null) {
  // REST fallback
  const url = `${apiHost}/api/unstable/wallets/${wallet.address}/transfers?chain=${encodeURIComponent(chain)}&tokens=${encodeURIComponent(tokens)}&status=${encodeURIComponent(status)}&limit=${limit}`;
  const res = await fetch(url, { headers: { "X-API-KEY": apiKey } });
  if (!res.ok) {
    process.stderr.write(`FAIL: REST transfers ${res.status} from ${url}\n`);
    process.stderr.write(await res.text() + "\n");
    process.exit(1);
  }
  const json = await res.json();
  transfers = json.data || [];
  source = "rest";
}

__cmsLog(JSON.stringify({
  address: wallet.address,
  chain,
  alias,
  count: transfers.length,
  source,
  transfers,
}, null, 2));
