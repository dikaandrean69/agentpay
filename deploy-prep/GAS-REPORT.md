# Deploy gas report — AgentPay (Binance Agent ID Hackathon)

Measured 19 Nov 2026 ~09:10–09:15 WIB. All on-chain figures fresh from BSC
mainnet (chain 56) at that time. Deploy executed 19 Nov ~09:25 WIB via CREATE2
(see DEPLOY-RESULT.md); figures below are the pre-deploy measurements.

## Method

- Balances: `cast balance` via `https://bsc.publicnode.com` (cross-checked
  gas price on 3 RPCs: publicnode, bsc-dataseed.binance.org,
  bsc-dataseed1.defibit.io — all returned 50,000,000 wei = 0.05 gwei).
- Recent block txs confirm real transactions landing at ~0.05 gwei
  (gasPrice 50,000,031 / 57,500,005 in the sampled block).
- Deploy gas: `forge script script/Deploy.s.sol --rpc-url
  https://bsc.publicnode.com --sender 0x5A3a499b09c064b58AF03cE9ccb8bF2649E90Ce5`
  (dry-run simulation against real BSC state, no broadcast, no key).
  Same for `script/DeployMinimal.s.sol`.
- Agent ID holdings: `balanceOf` on Agent ID contract
  `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.

## Fresh balances (BNB, on-chain)

| Wallet | Address | Balance (BNB) | Agent ID |
| --- | --- | --- | --- |
| Main (elmalihana05) | 0xC44C7eA964ebBC8eC4b64f1db25Fd3194C6f81E0 | 0.000011102098443081 | 1 ✅ |
| Second (dikaandrean69) | 0xEEbC77cA7f8fBFb2182e5D355063eB4ab3fCAC5e | 0.000114309866280731 | 1 ✅ |
| Third (#64355) | 0x5A3a499b09c064b58AF03cE9ccb8bF2649E90Ce5 | 0.000136517712325720 | 1 ✅ |
| Selling | 0xd167827E2be1c121ebb4593885F773e558a7Cc65 | 0 | 0 |

## Deploy cost (measured)

| Contract | Gas | @ 0.05 gwei | @ 0.1 gwei | @ 1 gwei |
| --- | --- | --- | --- | --- |
| AgentPay (full) | 1,478,270 | **0.0000739135 BNB** | 0.0001478270 BNB | 0.0014782700 BNB |
| AgentPayMinimal (no isDue/dueCount) | 1,288,246 | 0.0000644123 BNB | 0.0001288246 BNB | 0.0012882460 BNB |

Minimal variant saves 190,024 gas (~13%, 0.0000095 BNB @ 0.05 gwei) by
dropping the two keeper view helpers. Trade-off: keeper bots lose the
on-chain `isDue`/`dueCount` helpers (they can compute due-ness off-chain
from `getPlan` instead).

EIP-1167 minimal proxy: a clone deploy is ~45,000–60,000 gas, BUT it
requires the implementation contract deployed first (1,478,270 gas) — total
for a single instance ≈ 1.53M+ gas, MORE than deploying the full contract
directly. Only cheaper when deploying many instances. **Not cheaper here.**

## Verdict — can any wallet afford the deploy?

**YES — at the gas price measured right now (0.05 gwei): second and third
wallets can; main cannot.**

| Wallet | Full deploy (0.0000739135) | Minimal (0.0000644123) |
| --- | --- | --- |
| Main 0.0000111021 | ❌ short by 0.0000628114 (needs 6.66× its balance) | ❌ short by 0.0000533102 (5.80×) |
| Second 0.0001143099 | ✅ leaves 0.0000403964 | ✅ leaves 0.0000498976 |
| Third 0.0001365177 | ✅ leaves 0.0000626042 | ✅ leaves 0.0000721054 |
| Selling 0 | ❌ | ❌ |

Post-deploy buffer (at 0.05 gwei, indicative from test gas): `createPlan`
~341,469 gas ≈ 0.0000171 BNB; `approve` ~46,000 gas ≈ 0.0000023 BNB;
`executePayment` ~150,000–500,000 gas ≈ 0.0000075–0.000025 BNB.
Third wallet after a full deploy (0.0000626 left) covers roughly a demo
round: 1× createPlan + 1× approve + 1× execute + spare change. Second
wallet (0.0000404 left) covers it more tightly. Main wallet cannot deploy
at all and would need a top-up to do anything on-chain.

**Gas-price risk (read this before deploying):** at 0.1 gwei the full
deploy costs 0.0001478 BNB — more than ANY wallet holds (third max
0.0001365). At 0.1 gwei only the minimal variant fits the third wallet, and
only barely (leaves 0.0000077). At 1 gwei nothing fits. Deploy must happen
while BSC gas is ~0.05 gwei; re-check `cast gas-price` immediately before
broadcasting, and abort if it has risen.

## Recommendation

- Deployer: **third wallet** `0x5A3a…` (largest post-deploy buffer).
- Contract: **full AgentPay** (the view helpers are worth 0.0000095 BNB for
  keeper UX and the Innovation "product completion" story); minimal is the
  fallback if gas rises toward 0.1 gwei.
- Reward receiving address on the submission form: main wallet
  `0xC44C…` (elmalihana05 identity) — separate from the deployer; the
  contract has no owner, so the deployer address carries no privilege.
- No top-up and no inter-wallet transfers were made or assumed; if the user
  wants a bigger safety margin, that is his decision.
