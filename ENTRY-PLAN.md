# ENTRY-PLAN — Binance Agent ID Hackathon (60,000 USDC)

Source of rules: official announcement, re-read live 19 Nov 2026 09:08 WIB:
https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf
(crawled 2026-11-19 02:08 UTC).

## Key dates (all verified from the announcement)

| Milestone | Time |
| --- | --- |
| Submission period | 18 Nov 2026 08:00 UTC – 9 Dec 2026 08:00 UTC (= **15:00 WIB**) |
| Internal review | 9 – 17 Dec 2026 |
| Public review | 17 – 20 Dec 2026 |
| Payout | ≤ 14 business days after public review ends |

## Prize splits (verified)

| Award | Pool | Split (top 10 each) |
| --- | --- | --- |
| Growth Award | 29,000 USDC | 1st 10,000 / 2nd 6,000 / 3rd 4,000 / 4th 3,000 / 5th 2,000 / 6th–10th 800 |
| Innovation Award | 29,000 USDC | same split |
| X Promotion Award | 2,000 USDC | 20 winners × $100, judged on post quality |

Extra: each of the 20 project winners (both awards) additionally gets one
eligibility spot to claim a **two-digit Agent ID**. Each project may only
receive **one award**. New AND existing projects eligible; for existing
projects only data generated during the Submission Period counts.

## The project: AgentPay

Non-custodial recurring-payments agent on BNB Chain, gated by Agent ID.
A `name.ai` holder creates a payment plan (token, payee, amount/interval,
max payments, budget); any keeper executes due payments via `transferFrom`.
Contract never holds funds; payer revokes/pauses/cancels anytime.
Port of AevumPay (DoraHacks Aevum #1, 14/14 tests) + Agent ID gate as the
new core feature. Repo: `~/workspace/binance-agent-id-hackathon/`
(`forge test` **20/20 PASS**, anvil demo green). **Deployed 19 Nov 2026 ~09:25 WIB**
via CREATE2: `0x53f8f65618876253b4c6eAC80a3187E34A43A16f`.

## Lane 1 — Growth Award (29,000 USDC, metric-ranked)

What it needs: top-10 by weighted on-chain metrics during the Submission
Period — **number of interacting Agent ID addresses**, tx volume, tx count.
Only submitted contract addresses count; interacting addresses must hold an
Agent ID. Ranking from real on-chain data, computed by the Binance Wallet team.

| Item | Status |
| --- | --- |
| Contract built + tested (20/20) | ✅ DONE |
| Deploy on BNB Chain | ✅ DONE 19 Nov 2026 (CREATE2, `0x53f8f6…`) |
| Agent ID holders interacting in-period | ⛔ BLOCKED — no user base yet (3 holders: the user's own 3 wallets) |

Honest assessment: Growth is a numbers game against every project in the
ecosystem. With only the user's own 3 Agent ID wallets interacting, the
project will not rank top 10 on metrics. Growth is only reachable if the
project gets real distribution after deploy (e.g. shared in Agent ID /
Binance Wallet communities, other Agent ID holders creating plans). The
contract is designed to make each interaction count: every plan creation and
every keeper execution is an on-chain interaction by an Agent ID holder
(payer) or any keeper.

## Lane 2 — Innovation Award (29,000 USDC, panel-judged)

What it needs: product **live** with **≥ 30 Agent ID addresses** having
interacted with the submitted contract(s) during the Submission Period.
Panel scores 100 points: Agent ID Application Depth 30% / Practicality &
Feasibility 25% / Product Completion 25% / Innovation 20%.

| Item | Status |
| --- | --- |
| Contract built + tested (20/20) | ✅ DONE |
| Agent ID depth: gate is core access control + identity (30% criterion) | ✅ DONE |
| Practicality: recurring stablecoin payouts is a real need | ✅ DONE |
| Product live (deployed + verified + usable) | ✅ DONE (deployed; Sourcify verified exact match; BscScan verify pending — Cloudflare-blocked in cloud browser) |
| ≥ 30 interacting Agent ID addresses | ⛔ BLOCKED — no user base yet |

Honest assessment: the build scores well on depth/practicality/innovation
as a design, but the **eligibility threshold (30 Agent ID addresses) is a
hard gate** — without 30 distinct Agent ID holders interacting in-period,
the project cannot win Innovation regardless of quality. This is the single
biggest blocker after deploy. Reaching 30 needs distribution: the user (or
the project) must get 30 Agent ID holders to create a plan or execute a
payment before 9 Dec 15:00 WIB. No shortcut is acceptable — the rules
disqualify mass account registration / volume manipulation.

## Lane 3 — X Promotion Award (2,000 USDC, 20 × $100)

What it needs: post **original content on X** about participating projects,
include **both hashtags #BinanceWalletHackathon and #AgenticWallet**, submit
the X link via the official survey (app.binance.com, linked in the
announcement). 20 winners selected on post quality.

| Item | Status |
| --- | --- |
| Promo post drafts (3 variants, hashtags included) | ✅ DONE — `X-PROMO-DRAFTS.md` |
| Posting X account | ⛔ BLOCKED — @elmalihana05 and @dikaandrean691 suspended; safe handle not given |
| Survey submission of the X link | ⏳ after posting |

Honest assessment: this is the most reachable $100 — it needs no deploy,
no gas, no 30 users, only a posting X account and a good post. Blocked
purely on the account. Drafts are ready to post the moment a usable handle
exists.

## Blockers (do NOT work around — record honestly)

### 1. Deploy gas — SOLVED (deployed 19 Nov 2026 via CREATE2)
Fresh on-chain balances 19 Nov ~09:10 WIB (BSC, 3 RPCs agree, gas 0.05 gwei):
main 0.0000111021 BNB (**cannot deploy** — needs 6.7× its balance), second
0.0001143099 BNB (**can deploy**, leaves 0.0000404), third 0.0001365177 BNB
(**can deploy**, leaves 0.0000626), selling 0 BNB.
Deploy cost measured by simulation on real BSC state: AgentPay full
1,478,270 gas = **0.0000739135 BNB** @ 0.05 gwei; minimal variant 1,288,246
gas = 0.0000644123 BNB. Full numbers + sensitivity in
`deploy-prep/GAS-REPORT.md`.
⚠️ Gas-price risk: at 0.1 gwei the full deploy costs 0.0001478 BNB — more
than ANY wallet holds. Deploy must happen while gas is ~0.05 gwei.
No top-up, no moving funds between wallets — that needs the user's say.
Recommended deployer when approved: **third wallet** (largest post-deploy
buffer), full contract.

### 2. 30 Agent ID users — OPEN
No user base. Needs distribution after deploy; cannot be faked (rules
disqualify it). This decides Innovation eligibility and Growth ranking.

### 3. Posting X account — OPEN
Both known X accounts suspended; safe handle never given. Drafts ready.

### 4. Public repo + BscScan verification — READY TO DO AFTER DEPLOY
Repo must be public on GitHub (user's account dikaandrean69; connector
cannot create repos or push binaries — needs browser, as with
make-fun-guide). BscScan verification is free (no gas).

## What remains, in order (needs the user)

1. **BscScan verification** — retry later or from the user's own browser
   (Cloudflare-blocked in the cloud browser); Sourcify already verified
   exact match.
2. **Distribution for 30 Agent ID holders** — user's call on how to reach
   them (communities, friends with Agent IDs, etc.).
3. **X account** — give the safe handle (or post the drafts himself).
4. **Submit the project form** during the Submission Period (draft content
   in `SUBMISSION-DRAFT.md`) + submit X links via the official survey.
