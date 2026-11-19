// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/AgentPay.sol";
import "../src/MockUSD8.sol";
import "../src/MockAgentID.sol";

interface Vm {
    function warp(uint256) external;
    function prank(address) external;
    function startPrank(address) external;
    function stopPrank() external;
    function expectRevert(bytes calldata) external;
    function expectEmit(bool, bool, bool, bool) external;
    function deal(address, uint256) external;
    function label(address, string calldata) external;
}

contract AgentPayTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    MockUSD8 token;
    MockAgentID agentId;
    AgentPay agent;

    address payer = address(0x1001);
    address payee = address(0x2002);
    address keeper = address(0x3003);
    address stranger = address(0x4004); // holds no Agent ID

    function assertEq(uint256 a, uint256 b) internal pure {
        require(a == b, "assertEq uint256 failed");
    }

    function assertEq(address a, address b) internal pure {
        require(a == b, "assertEq address failed");
    }

    function assertTrue(bool condition) internal pure {
        require(condition, "assertTrue failed");
    }

    function assertFalse(bool condition) internal pure {
        require(!condition, "assertFalse failed");
    }

    function setUp() public {
        token = new MockUSD8();
        agentId = new MockAgentID();
        agent = new AgentPay(address(agentId));

        // payer and keeper hold an Agent ID; payee and stranger do not.
        agentId.setBalance(payer, 1);
        agentId.setBalance(keeper, 1);

        token.mint(payer, 10_000 * 1e6);

        vm.prank(payer);
        token.approve(address(agent), 10_000 * 1e6);
    }

    // ---- Agent ID gating (new vs AevumPay) ----

    function testHoldsAgentIdView() public {
        assertTrue(agent.holdsAgentId(payer));
        assertTrue(agent.holdsAgentId(keeper));
        assertFalse(agent.holdsAgentId(payee));
        assertFalse(agent.holdsAgentId(stranger));
    }

    function testCreatePlanRevertsWithoutAgentId() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(NotAgentIdHolder.selector));
        agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);
    }

    function testCreatePlanRevertsWhenAgentIdRevoked() public {
        agentId.setBalance(payer, 0);
        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSelector(NotAgentIdHolder.selector));
        agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);
    }

    function testPayeeNeedsNoAgentId() public {
        // payee holds no Agent ID; plan creation + payment must still work.
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);
        agent.executePayment(planId);
        assertEq(token.balanceOf(payee), 100e6);
    }

    function testKeeperNeedsNoAgentIdToExecute() public {
        // executePayment stays permissionless: even a non-holder keeper can run it.
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);
        vm.prank(stranger);
        agent.executePayment(planId);
        AgentPay.Plan memory p = agent.getPlan(planId);
        assertEq(p.paymentsMade, 1);
    }

    function testConstructorRevertsOnZeroAgentId() public {
        vm.expectRevert(abi.encodeWithSelector(ZeroAddress.selector));
        new AgentPay(address(0));
    }

    // ---- Ported PayAgent behaviour (14 tests) ----

    function testCreatePlanStoresFields() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);

        AgentPay.Plan memory p = agent.getPlan(planId);
        assertEq(p.payer, payer);
        assertEq(p.payee, payee);
        assertEq(p.token, address(token));
        assertEq(p.amountPerPayment, 100e6);
        assertEq(p.intervalSeconds, 7 days);
        assertEq(p.startTime, block.timestamp);
        assertEq(p.nextDue, block.timestamp);
        assertEq(p.paymentsMade, 0);
        assertEq(p.totalPaid, 0);
        assertEq(p.maxPayments, 5);
        assertEq(p.budget, 500e6);
        assertTrue(p.active);
        assertFalse(p.paused);
        assertEq(agent.nextPlanId(), 1);
    }

    function testCreatePlanRevertsOnZeroAmount() public {
        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSelector(ZeroAmount.selector));
        agent.createPlan(address(token), payee, 0, 7 days, block.timestamp, 5, 500e6);
    }

    function testCreatePlanRevertsOnZeroPayee() public {
        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSelector(ZeroAddress.selector));
        agent.createPlan(address(token), address(0), 100e6, 7 days, block.timestamp, 5, 500e6);
    }

    function testExecuteBeforeDueReverts() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp + 1 days, 5, 500e6);

        vm.expectRevert(abi.encodeWithSelector(NotDue.selector));
        agent.executePayment(planId);
    }

    function testExecutePaymentMovesTokens() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);

        uint256 payerBalBefore = token.balanceOf(payer);
        uint256 payeeBalBefore = token.balanceOf(payee);

        agent.executePayment(planId);

        assertEq(token.balanceOf(payer), payerBalBefore - 100e6);
        assertEq(token.balanceOf(payee), payeeBalBefore + 100e6);

        AgentPay.Plan memory p = agent.getPlan(planId);
        assertEq(p.paymentsMade, 1);
        assertEq(p.totalPaid, 100e6);
        assertEq(p.nextDue, p.startTime + 7 days);
    }

    function testExecuteSecondPaymentAfterWarp() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);

        agent.executePayment(planId);

        vm.warp(block.timestamp + 7 days);
        agent.executePayment(planId);

        AgentPay.Plan memory p = agent.getPlan(planId);
        assertEq(p.paymentsMade, 2);
    }

    function testExecuteByKeeperAllowed() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);

        vm.prank(keeper);
        agent.executePayment(planId);

        AgentPay.Plan memory p = agent.getPlan(planId);
        assertEq(p.paymentsMade, 1);
    }

    function testMaxPaymentsEnforced() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 1, 500e6);

        agent.executePayment(planId);

        vm.warp(block.timestamp + 7 days);
        vm.expectRevert(abi.encodeWithSelector(MaxPaymentsReached.selector));
        agent.executePayment(planId);
    }

    function testBudgetEnforced() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 0, 150e6);

        agent.executePayment(planId);

        vm.warp(block.timestamp + 7 days);
        vm.expectRevert(abi.encodeWithSelector(BudgetExceeded.selector));
        agent.executePayment(planId);
    }

    function testCancelStopsPayments() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);

        vm.prank(keeper);
        vm.expectRevert(abi.encodeWithSelector(NotPayer.selector));
        agent.cancelPlan(planId);

        vm.prank(payer);
        agent.cancelPlan(planId);

        vm.expectRevert(abi.encodeWithSelector(NotActive.selector));
        agent.executePayment(planId);
    }

    function testPauseAndResume() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);

        vm.prank(payer);
        agent.pausePlan(planId);

        vm.expectRevert(abi.encodeWithSelector(NotActive.selector));
        agent.executePayment(planId);

        vm.prank(payer);
        agent.resumePlan(planId);

        agent.executePayment(planId);
        AgentPay.Plan memory p = agent.getPlan(planId);
        assertEq(p.paymentsMade, 1);
    }

    function testInsufficientAllowanceReverts() public {
        address freshPayer = address(0x5005);
        agentId.setBalance(freshPayer, 1);
        token.mint(freshPayer, 1000e6);

        vm.prank(freshPayer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 5, 500e6);

        vm.expectRevert(abi.encodeWithSelector(InsufficientAllowance.selector));
        agent.executePayment(planId);
    }

    function testIsDueAndDueCount() public {
        uint256 startTime = block.timestamp + 1 days;
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, startTime, 5, 500e6);

        assertFalse(agent.isDue(planId));
        assertEq(agent.dueCount(planId), 0);

        vm.warp(startTime);
        assertTrue(agent.isDue(planId));
        assertEq(agent.dueCount(planId), 1);

        vm.warp(startTime + 7 days);
        assertTrue(agent.isDue(planId));
        assertEq(agent.dueCount(planId), 2);
    }

    function testUnlimitedPlan() public {
        vm.prank(payer);
        uint256 planId = agent.createPlan(address(token), payee, 100e6, 7 days, block.timestamp, 0, 0);

        agent.executePayment(planId);

        vm.warp(block.timestamp + 7 days);
        agent.executePayment(planId);

        vm.warp(block.timestamp + 7 days);
        agent.executePayment(planId);

        AgentPay.Plan memory p = agent.getPlan(planId);
        assertEq(p.paymentsMade, 3);
    }
}
