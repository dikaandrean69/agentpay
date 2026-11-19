# Submission form draft — AgentPay (Binance Agent ID Hackathon)

**STATUS: DRAFT ONLY. Nothing submitted.** Submit during the Submission
Period (until 9 Dec 2026 15:00 WIB) via the official form linked in the
announcement. One project per team — this is the team's single project.

## Project name

**AgentPay**

## Website

(TBD — no website deployed yet. Options when ready: a minimal static page
describing the project + contract address + how to use it, hosted on GitHub
Pages from the public repo. Do NOT invent a domain; leave blank or link the
GitHub repo until a real site exists.)

## Contract address(es)

- AgentPay (BNB Chain, chain 56): `0x53f8f65618876253b4c6eAC80a3187E34A43A16f` (deployed 19 Nov 2026 ~09:25 WIB via CREATE2 factory, tx `0x1a2654de0a0971e2a6172c101870cbdc8a46c44cdf3392fe447621d8e98e79a5`, salt 0)
- Agent ID contract (reference, not ours): `0x60B9262456de011f7d15a54cdd8c48baaa8b022f`
  (SPACE ID Agent ID, ERC-721, non-transferable)

Only the AgentPay address above is submitted for metric counting.

## Agent ID usage description

AgentPay is a non-custodial recurring-payments agent where **Agent ID is the
access control and identity layer**:

1. **Access control** — `createPlan()` reverts with `NotAgentIdHolder`
   unless the caller holds an Agent ID (`balanceOf > 0` on the SPACE ID
   Agent ID contract). Only a `name.ai` holder can create a payment plan.
2. **Identity** — every plan is tied on-chain to the payer's Agent ID
   holder address; `holdsAgentId(address)` is a public view anyone can
   check.
3. **Payments** — the plan pays a chosen payee in ERC-20 (e.g. BSC USDT) on
   a schedule (amount / interval / max payments / budget cap). Execution is
   permissionless: any keeper (bot, payee, payer) can call `executePayment`
   when a payment is due, so an AI agent acting for an Agent ID holder can
   run its own payables.
4. **User custody** — the contract never holds funds. Payments are pulled
   via `transferFrom` from the payer's own balance; the payer can revoke the
   allowance, pause, or cancel at any time. No unlimited approval is ever
   requested.

## Project description (short, for the form)

AgentPay lets any AI agent or business with an Agent ID (`name.ai`) set up
recurring stablecoin payments on BNB Chain — salaries, subscriptions,
retainers — without giving up custody. The agent's identity IS its Agent ID:
only Agent ID holders can create plans, every plan is verifiably tied to a
`name.ai` holder, and keepers execute payments permissionlessly when due.
Spending limits (per-payment amount, total budget, max payment count) and
instant revoke/pause/cancel keep the payer in control at all times.

## Links

- Public repo (live 19 Nov 2026): `https://github.com/dikaandrean69/agentpay`
- BscScan: `https://bscscan.com/address/0x53f8f65618876253b4c6eAC80a3187E34A43A16f` (source verified on Sourcify, exact match — see DEPLOY-RESULT.md; BscScan Etherscan-API verification still needs a free API key)
- Announcement: https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf

## Reward receiving address

Main wallet `0xC44C7eA964ebBC8eC4b64f1db25Fd3194C6f81E0` (elmalihana05).
(Deployer will be the third wallet `0x5A3a499b09c064b58AF03cE9ccb8bF2649E90Ce5`
— the contract has no owner, so the deployer address carries no privilege.)

## Award lanes targeted

- **Growth Award** — metric-ranked; needs interacting Agent ID addresses
  in-period (distribution still open).
- **Innovation Award** — panel-judged; needs the product live + ≥ 30
  interacting Agent ID addresses (distribution still open).
- (X Promotion Award is separate — post + survey, see `X-PROMO-DRAFTS.md`.)

## Safety / red-line statement (for the form if asked)

- No web QR login; no session storage; no signing on behalf of users.
- No bypass of user transaction confirmation; every user action is the
  user's own signed transaction.
- No unauthorized transfers; no unlimited approvals requested; contract
  never holds user funds.
- Contract open-source (MIT), no owner role, no admin pause, no mint, no
  tax, no fund withdrawal.
- No use of "Binance"/"BNB" in the project name or branding.
- No collection of seeds, keys, API secrets, or pairing codes.
- No returns promised. Agent ID is not used to look up other people's
  wallets by name.
