# AgentPay — Binance Agent ID Hackathon entry

Non-custodial on-chain payables agent on **BNB Chain**, gated by **Agent ID**.
Built 19 Nov 2026 for the Agent ID Hackathon (submission 18 Nov 15:00 WIB –
9 Dec 2026 15:00 WIB). **Deployed 19 Nov 2026 ~09:25 WIB** via CREATE2:
contract `0x53f8f65618876253b4c6eAC80a3187E34A43A16f`, tx
`0x1a2654de0a0971e2a6172c101870cbdc8a46c44cdf3392fe447621d8e98e79a5`,
[Sourcify verified (exact match)](https://sourcify.dev/server/v2/contract/56/0x53f8f65618876253b4c6eAC80a3187E34A43A16f).

## Concept

An AI agent (or a business) that holds an Agent ID (`name.ai`) creates a
recurring payment plan — e.g. "pay 100 USDT every 7 days, max 3 payments,
budget 300 USDT". Any keeper (bot, payee, or payer) executes each payment
when due. The contract **never holds user funds**: every payment is pulled
from the payer via ERC-20 `transferFrom`, so the payer keeps custody and can
stop payments instantly by revoking the allowance, pausing, or cancelling.

Agent ID is the product's core, not a bolt-on:
- **Access control** — `createPlan` reverts unless the caller holds an Agent
  ID (`balanceOf > 0` on the SPACE ID Agent ID contract). No Agent ID, no plan.
- **Identity** — the payer *is* their Agent ID; every plan is tied to a
  `name.ai` holder, on-chain and verifiable.
- **Payments** — recurring stablecoin payouts (default token BSC USDT),
  executed permissionlessly by keepers.

## Contracts

| File | Description |
| --- | --- |
| `src/AgentPay.sol` | Payables agent + Agent ID gate. No external deps. |
| `src/AgentPayMinimal.sol` | Same, minus `isDue`/`dueCount` view helpers — gas comparison only. |
| `src/MockUSD8.sol` | Local test-only ERC-20, 6 decimals. Never deploy live. |
| `src/MockAgentID.sol` | Local test-only Agent ID mock (`balanceOf`). Never deploy live. |
| `test/AgentPay.t.sol` | 20 Foundry tests (14 ported + 6 Agent ID gate tests). |
| `script/Deploy.s.sol` | Deploy AgentPay on BSC (Agent ID `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`). |
| `script/DeployMinimal.s.sol` | Same for the minimal variant (gas comparison). |
| `script/Demo.s.sol` | Local anvil end-to-end demo only. |

## Local verification (19 Nov 2026)

```bash
forge build   # clean (solc 0.8.20, optimizer on)
forge test    # 20 passed; 0 failed; 0 skipped
```

Anvil end-to-end demo (`script/Demo.s.sol`, `--unlocked`): MockAgentID
`0x5fbdb2315678afecb367f032d93f642f64180aa3`, MockUSD8
`0xe7f1725e7734ce288f8367e1bb143e90bb3f0512`, AgentPay
`0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0` — plan 100/7 days/max 3/budget
300, payment 1 executed: payer 1,000,000e6 → 999,900e6, payee 0 → 100e6,
`paymentsMade` 1, `isDue` false until next interval, `holdsAgentId` true for
the holder / false for a stranger.

## Deploy gas (measured, BSC mainnet state simulation, 19 Nov ~09:15 WIB)

Gas price live: **0.05 gwei** (confirmed on 3 RPCs + recent block txs).

| Contract | Gas | Cost @ 0.05 gwei |
| --- | --- | --- |
| AgentPay (full) | 1,478,270 | **0.0000739135 BNB** |
| AgentPayMinimal | 1,288,246 | 0.0000644123 BNB |

Fresh wallet balances (same time, on-chain): main `0xC44C…` **0.0000111021
BNB** — NOT enough (needs 6.7× its balance); second `0xEEbC…`
**0.0001143099 BNB** — enough (leaves 0.0000404); third `0x5A3a…`
**0.0001365177 BNB** — enough (leaves 0.0000626); selling `0xd167…` **0 BNB**.
Full numbers + gas-price sensitivity in `deploy-prep/GAS-REPORT.md`.

**Deployed 19 Nov 2026 ~09:25 WIB** via CREATE2 (canonical deterministic
deployment proxy, salt 0) from the third wallet: contract
`0x53f8f65618876253b4c6eAC80a3187E34A43A16f`, tx
`0x1a2654de0a0971e2a6172c101870cbdc8a46c44cdf3392fe447621d8e98e79a5`, cost
~0.0000775 BNB. Full record in `DEPLOY-RESULT.md`.

## Origin

Port of **AevumPay** (`~/workspace/makefun/aevum-01-entry/`, DoraHacks Aevum
Builder Challenge #1, 14/14 tests, built 16 Nov 2026, still undeployed on
Aevum testnet for lack of tQDAY). The BSC port keeps the audited payables
logic and adds the Agent ID gate + `holdsAgentId` view as the new core
feature. This is a separate project for this hackathon (one project per team).

## Hackathon lanes

See `ENTRY-PLAN.md` (lane-by-lane: needs, built status, blockers) and
`SUBMISSION-DRAFT.md` (form content) and `X-PROMO-DRAFTS.md` (promo posts,
ready to post once a posting X account exists).

## Safety / red-line compliance

- No web QR login, no session storage, no signing on behalf of users.
- No bypass of user tx confirmation: every user action (create plan,
  approve, cancel) is the user's own signed transaction.
- No unlimited approvals requested: the payer approves exactly the allowance
  they choose and can set it to 0 at any time; the contract never holds funds.
- Contract is MIT open-source; no owner role, no pause-by-admin, no mint,
  no tax, no fund withdrawal — the deployer has no special powers.
- No brand impersonation: project name "AgentPay" uses neither "Binance"
  nor "BNB". No returns promised anywhere.
- Agent ID is NOT used to look up other people's wallets by name.
