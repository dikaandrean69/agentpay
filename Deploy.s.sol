// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/AgentPay.sol";

interface Vm {
    function broadcast() external;
    function startBroadcast() external;
    function stopBroadcast() external;
    function envOr(string calldata, address) external returns (address);
}

/// @notice Deploys AgentPay on BNB Chain (chain 56).
/// @dev Agent ID contract is fixed: 0x60b9262456de011f7d15a54cdd8c48baaa8b022f (SPACE ID Agent ID, ERC-721).
///      No mock token is deployed on live networks. Set AGENT_ID env only to override (tests / local).
///      DRY RUN (no broadcast, no key, no gas spent):
///        forge script script/Deploy.s.sol --rpc-url https://bsc.publicnode.com --sender <DEPLOYER>
///      REAL DEPLOY (needs a funded deployer key — NEVER commit one):
///        forge script script/Deploy.s.sol --rpc-url https://bsc.publicnode.com --private-key $PRIVATE_KEY --broadcast
///      VERIFY on BscScan (free):
///        forge verify-contract --chain-id 56 --verifier etherscan --etherscan-api-key $BSCSCAN_API_KEY <ADDR> src/AgentPay.sol:AgentPay --constructor-args 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
contract Deploy {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    event Deployed(address agentPay, address agentId);

    function run() external {
        address agentIdAddr = vm.envOr("AGENT_ID", AGENT_ID);

        vm.startBroadcast();
        AgentPay agent = new AgentPay(agentIdAddr);
        vm.stopBroadcast();

        emit Deployed(address(agent), agentIdAddr);
    }
}
