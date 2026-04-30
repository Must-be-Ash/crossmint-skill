// x402-probe: send a no-payment request, parse the 402 body if present.
// Reads URL from env. Outputs JSON to stdout, never spends.

const __cmsRealStdoutWrite = process.stdout.write.bind(process.stdout);
process.stdout.write = function (chunk, enc, cb) { return process.stderr.write(chunk, enc, cb); };
const __cmsLog = (...a) => __cmsRealStdoutWrite(a.map(x => typeof x === "string" ? x : JSON.stringify(x)).join(" ") + "\n");
console.log = (...a) => process.stderr.write(a.join(" ") + "\n");

const url = process.env.URL;
if (!url) { process.stderr.write("FAIL: URL env var required\n"); process.exit(2); }

const probe = await fetch(url, { method: "GET" });

if (probe.status !== 402) {
  __cmsLog(JSON.stringify({
    isX402: false,
    status: probe.status,
    url,
    body: await probe.text(),
  }, null, 2));
  process.exit(0);
}

const body = await probe.json();
const accept = body.accepts?.[0] || {};
const maxRaw = String(accept.maxAmountRequired || "0");
const maxUsd = (Number(maxRaw) / 1_000_000).toFixed(6);

__cmsLog(JSON.stringify({
  isX402: true,
  status: 402,
  url,
  x402Version: body.x402Version,
  network: accept.network,
  scheme: accept.scheme,
  asset: accept.asset,
  payTo: accept.payTo,
  maxAmountRequired: maxRaw,
  maxAmountUSD: `$${maxUsd}`,
  resource: accept.resource,
  raw: body,
}, null, 2));
