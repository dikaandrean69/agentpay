// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/AgentPay.sol";
import "../src/MockUSD8.sol";
import "../src/MockAgentID.sol";

interface Vm {
    function broadcast() external;
    function startBroadcast() external;
    function stopBroadcast() external;
    function envOr(string calldata, address) external returns (address);
    function prank(address) external;
}

/// @notice Local anvil end-to-end demo only (never use on a live network).
/// @dev Deploys MockAgentID + MockUSD8 + AgentPay, gives the sender an Agent ID,
///      funds it, creates a plan (100 test-USD / 7 days, max 3, budget 300),
///      executes payment 1, warps are not possible in a script — payment 2 is
///      left for manual follow-up. Run: anvil & forge script script/Demo.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --sender <ADDR> --private-key <ANVIL_KEY>
contract Demo {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    event DemoDeployed(address mockAgentId, address mockToken, address agentPay);
    event DemoPlan(uint256 planId, address payer, address payee, uint256 paid);

    function run() external {
        vm.startBroadcast();
        MockAgentID mockId = new MockAgentID();
        MockUSD8 token = new MockUSD8();
        AgentPay agent = new AgentPay(address(mockId));

        address sender = msg.sender;
        mockId.setBalance(sender, 1);
        token.mint(sender, 1_000_000 * 1e6);
        token.approve(address(agent), 1_000_000 * 1e6);

        uint256 planId = agent.createPlan(address(token), address(0x2002), 100e6, 7 days, block.timestamp, 3, 300e6);
        agent.executePayment(planId);
        vm.stopBroadcast();

        emit DemoDeployed(address(mockId), address(token), address(agent));
        emit DemoPlan(planId, sender, address(0x2002), token.balanceOf(address(0x2002)));
    }
}
