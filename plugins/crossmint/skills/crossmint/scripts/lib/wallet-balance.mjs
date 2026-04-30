// wallet-balance: report USDC, USDXM, native balance.
// USDC is ALWAYS verified by reading the canonical contract directly via viem,
// because the SDK has been seen to under-report (real session: SDK said 0, contract said 18.97).
// Output is deterministic JSON; never fabricates a "0" without an authoritative source.

// Route SDK chatter to stderr; reserve stdout for the JSON result.
// Capture and silence everything written to stdout by transitive imports.
// We restore the writer at the end and emit the final JSON only.
const __cmsRealStdoutWrite = process.stdout.write.bind(process.stdout);
process.stdout.write = function (chunk, enc, cb) { return process.stderr.write(chunk, enc, cb); };
const __cmsLog = (...a) => __cmsRealStdoutWrite(a.map(x => typeof x === "string" ? x : JSON.stringify(x)).join(" ") + "\n");
console.log = (...a) => process.stderr.write(a.join(" ") + "\n");

const { createCrossmint, CrossmintWallets } = await import("@crossmint/wallets-sdk");
const { createPublicClient, http, formatUnits } = await import("viem");
const { base, baseSepolia } = await import("viem/chains");

const apiKey = process.env.CROSSMINT_SERVER_API_KEY || process.env.CROSSMINT_API_KEY;
if (!apiKey) { process.stderr.write("FAIL: no CROSSMINT_SERVER_API_KEY in env\n"); process.exit(1); }

const chain = process.env.CMS_DEFAULT_CHAIN || (process.env.CROSSMINT_ENV === "production" ? "base" : "base-sepolia");
const alias = process.env.WALLET_ALIAS || "claude-agent-wallet";

// Canonical USDC contracts. Source: Circle docs.
const USDC = {
  "base":         "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  "base-sepolia": "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
};

const ERC20_ABI = [
  { inputs: [{ name: "account", type: "address" }], name: "balanceOf", outputs: [{ name: "", type: "uint256" }], stateMutability: "view", type: "function" },
  { inputs: [], name: "decimals", outputs: [{ name: "", type: "uint8" }], stateMutability: "view", type: "function" },
];

const crossmint = createCrossmint({ apiKey });
const wallets = CrossmintWallets.from(crossmint);

let wallet;
try {
  wallet = await wallets.getWallet(`evm:alias:${alias}`, { chain });
} catch (e) {
  process.stderr.write(`FAIL: wallet not found. Run scripts/wallet.sh info to create it. ${e?.message || ""}\n`);
  process.exit(1);
}

const address = wallet.address;
const usdcContract = USDC[chain];
if (!usdcContract) {
  process.stderr.write(`FAIL: no canonical USDC contract known for chain ${chain}.\n`);
  process.exit(1);
}

// 1. Try the SDK (covers Crossmint-tracked tokens like USDXM)
let sdkResult = null;
try {
  sdkResult = await wallet.balances(["usdc", "usdxm"]);
} catch (_) {
  // SDK might fail; we still get USDC + native via direct contract reads below.
}

// 2. Direct on-chain reads for USDC (authoritative) + native ETH
const viemChain = chain === "base" ? base : baseSepolia;
const client = createPublicClient({ chain: viemChain, transport: http() });

const [usdcRaw, usdcDecimals, nativeRaw] = await Promise.all([
  client.readContract({ address: usdcContract, abi: ERC20_ABI, functionName: "balanceOf", args: [address] }),
  client.readContract({ address: usdcContract, abi: ERC20_ABI, functionName: "decimals" }),
  client.getBalance({ address }),
]);

// 3. Compose result
const usdcAmount = formatUnits(usdcRaw, usdcDecimals);

// USDXM only comes from the SDK
let usdxm = { amount: "0", source: "unavailable" };
if (sdkResult?.tokens) {
  const t = sdkResult.tokens.find(x => x?.symbol?.toLowerCase() === "usdxm");
  if (t) usdxm = { amount: String(t.amount ?? "0"), source: "sdk" };
} else if (sdkResult?.usdxm) {
  usdxm = { amount: String(sdkResult.usdxm.amount ?? "0"), source: "sdk" };
}

// SDK USDC for cross-check (informational)
let sdkUsdc = null;
if (sdkResult?.usdc) {
  sdkUsdc = String(sdkResult.usdc.amount ?? "0");
} else if (sdkResult?.tokens) {
  const t = sdkResult.tokens.find(x => x?.symbol?.toLowerCase() === "usdc");
  if (t) sdkUsdc = String(t.amount ?? "0");
}

const out = {
  address,
  chain,
  env: process.env.CROSSMINT_ENV || "staging",
  usdc: {
    amount: usdcAmount,
    raw: usdcRaw.toString(),
    contract: usdcContract,
    source: "onchain",
    sdkAgrees: sdkUsdc !== null ? (sdkUsdc === usdcAmount) : null,
    sdkAmount: sdkUsdc,
  },
  usdxm,
  native: {
    symbol: "ETH",
    amount: formatUnits(nativeRaw, 18),
    raw: nativeRaw.toString(),
    note: "smart wallets pay gas via paymaster — native ETH usually unnecessary",
  },
};

__cmsLog(JSON.stringify(out, null, 2));
