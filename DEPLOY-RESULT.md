# Deploy result — AgentPay on BNB Chain (chain 56)

**STATUS: DEPLOYED ✅ — 19 Nov 2026 ~09:25 WIB.** Contract live, code-verified
against local build, source verified on Sourcify (exact match).

User approval: "Deploy lewat CREATE2" (explicit approval for this method,
19 Nov ~09:21 WIB), after direct contract creation was verified impossible
through baw ("to is required for EVM contract-call").

## Deployed contract

| Field | Value |
|---|---|
| Contract | AgentPay (src/AgentPay.sol, constructor arg Agent ID `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`) |
| Address | `0x53f8f65618876253b4c6eAC80a3187E34A43A16f` |
| Tx hash | `0x1a2654de0a0971e2a6172c101870cbdc8a46c44cdf3392fe447621d8e98e79a5` |
| Block | 134422928 |
| Status | 1 (success) |
| Deployer (from) | Third wallet `0x5A3a499b09c064b58AF03cE9ccb8bF2649E90Ce5` |
| Method | CREATE2 via canonical deterministic deployment proxy (factory) |
| Factory | `0x4e59b44847b379578588920cA78FbF26c0B4956C` |
| Salt | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| Gas used | 1,139,347 (less than the 1,478,270 forge dry-run estimate) |
| Effective gas price | 68,014,824 wei (~0.068 gwei — rose slightly from 0.05 gwei at preview) |
| Fee paid | ~0.0000774925 BNB |
| Third-wallet balance after | 0.000059025226645792 BNB |
| BscScan | https://bscscan.com/address/0x53f8f65618876253b4c6eAC80a3187E34A43A16f |
| Sourcify | https://sourcify.dev/server/v2/contract/56/0x53f8f65618876253b4c6eAC80a3187E34A43A16f |

## Address correction (important)

The task brief listed the factory as
`0x4e59b44847b379578588920cA78FbF26c0B3B4` — that string is only 38 hex
characters, not a valid address (cast rejected it: "invalid string length").
The canonical deterministic deployment proxy address, confirmed by 4
independent sources (EIP-7997, deterministic-deployment-proxy README,
Cosmos docs, paritytech issue #263), is
**`0x4e59b44847b379578588920cA78FbF26c0B4956C`** (40 hex chars). The on-chain
code at that address was verified live and matches the EIP-7997 runtime code
byte-for-byte. The deploy used the corrected address.

## Factory interface (verified, not assumed)

The deterministic deployment proxy has NO `deploy()` function. Per its README
and EIP-7997, the calldata is `salt (32 bytes) ++ init code`, and the
factory's fallback invokes CREATE2 with salt = first 32 bytes, init code =
the rest. The baw call used exactly that: 32 zero bytes + AgentPay init code
(10,426 hex chars, creation bytecode + constructor arg for Agent ID).

## Pre-broadcast checks (all passed)

| Check | Result |
|---|---|
| `baw wallet address` (BSC, chain 56) | **0x5A3a499b09c064b58AF03cE9ccb8bF2649E90Ce5** — THIRD wallet ✅ |
| Factory code on BSC | Present, byte-identical to EIP-7997 runtime code ✅ |
| BSC gas price (live, at preview) | 50,000,000 wei = 0.05 gwei ✅ (abort threshold >0.06 gwei) |
| Third-wallet balance (live) | 0.000136517712325720 BNB ✅ |
| CREATE2 address precomputed (salt 0) | `0x53f8f65618876253b4c6eAC80a3187E34A43A16f`, independently recomputed via keccak — match ✅ |
| Code at predicted address before deploy | Empty (0x) ✅ |
| Dry-run simulation (`forge script`, real BSC state) | CLEAN — 1,478,270 gas ✅ |
| baw preview (`contract-call preview`, requestId `e30ea979f4074f72a158ef5e766357e2`) | success, simulationCode `000000000`, no simulation error, no balance/authority/allowance changes, no risks ✅ |

Broadcast summary (chain BSC 56 · from third wallet 0x5A3a… · to factory
0x4e59b44847b379578588920cA78FbF26c0B4956C · value 0 BNB · fee ~0.0000775 BNB).

## Post-deploy verification (all passed)

| Check | Result |
|---|---|
| Tx receipt | status 1, block 134422928, from third wallet, to factory ✅ |
| Code at predicted address | Present ✅ |
| Deployed runtime vs local compiled runtime | **Byte-for-byte MATCH** (after masking the immutable `agentId` slot, which is correctly filled with `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` at both use sites; masked sha256 `b2366673…` identical) ✅ |
| `agentId()` view call | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` ✅ |
| `holdsAgentId(third wallet)` | true ✅ |
| `holdsAgentId(main wallet)` | true ✅ |
| `nextPlanId()` | 0 (fresh contract) ✅ |
| Sourcify verification | **creationMatch: exact_match, runtimeMatch: exact_match** (chain 56) ✅ |

## BscScan verification — partially done (honest status)

- **Sourcify: VERIFIED, exact match** (both creation and runtime). Source is
  public and independently verifiable.
- **BscScan Etherscan-API verification: NOT done.** It requires a BscScan API
  key; none exists in this environment (no `$BSCSCAN_API_KEY`, none in
  config). Creating one at bscscan.com is free (~1 minute), then:
  ```bash
  forge verify-contract --chain-id 56 --verifier etherscan \
    --etherscan-api-key $BSCSCAN_API_KEY \
    0x53f8f65618876253b4c6eAC80a3187E34A43A16f src/AgentPay.sol:AgentPay \
    --constructor-args 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
  ```
  Note: the first Sourcify attempt appeared to time out (6 attempts), but the
  retry immediately reported "already verified" — the first submission had
  gone through. Do NOT re-submit blindly; check status first.

## What was NOT done (per the task's limits)

- No top-up, no inter-wallet transfers, no deploy from any other wallet.
- No private key requested, used, or logged anywhere (baw signed via the
  Binance App flow; `requireConfirmation` was false on the preview and the
  execute returned BROADCASTED directly).
- No BscScan verification fee paid (verification is free; only the missing
  API key blocks the Etherscan-API route).

## Remaining for the hackathon entry

1. BscScan Etherscan-API verification (needs a free API key — see above).
2. Public GitHub repo push (needs browser — connector cannot create repos).
3. 30 interacting Agent ID addresses (distribution — decides Innovation/Growth).
4. Posting X account for the X Promotion Award (drafts in X-PROMO-DRAFTS.md).
5. Submit the project form (draft updated with the deployed address in
   SUBMISSION-DRAFT.md).

## Files

- Deploy commands: `deploy-prep/DEPLOY-COMMANDS.md` (key-based path still
  accurate; baw CREATE2 path used here is documented in this file)
- Gas report: `deploy-prep/GAS-REPORT.md`
- Init code used: `/tmp/agentpay-initcode.txt` (10,426 hex chars)
- Factory calldata used: `/tmp/agentpay-factory-calldata.txt` (salt + init code)
- Previous blocked attempt: superseded by this file (direct creation via baw
  is impossible; CREATE2 factory path used instead)
