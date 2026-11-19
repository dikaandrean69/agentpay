// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error ZeroAddress();
error ZeroAmount();
error ZeroInterval();
error PlanNotFound();
error NotPayer();
error NotActive();
error NotDue();
error MaxPaymentsReached();
error BudgetExceeded();
error InsufficientAllowance();
error InsufficientBalance();
error AlreadyPaused();
error NotPaused();
error TransferFailed();
error NotAgentIdHolder();

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @notice Minimal interface of the SPACE ID Agent ID contract (ERC-721, non-transferable).
/// @dev The hackathon announcement defines the check: balanceOf(address) > 0 means the address holds an Agent ID.
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title AgentPay - Non-custodial On-Chain Payables Agent, gated by Agent ID
/// @notice Recurring payments pulled directly from payer balances via ERC-20 transferFrom.
/// @dev Agent ID is the product's access control + identity layer: only an address that
///      holds an Agent ID (name.ai) can create a payment plan. The contract never holds
///      user funds: payers keep custody and can stop payments at any time by revoking
///      the allowance, pausing, or cancelling the plan. Execution is permissionless
///      (any keeper — keeper bot, payee, or payer — may call executePayment), so an
///      AI agent acting for an Agent ID holder can run the schedule.
///      No unlimited approvals are requested by this contract: the payer approves
///      exactly the token allowance they choose, and can set it to 0 at any time.
contract AgentPay {
    struct Plan {
        address payer;
        address payee;
        address token;
        uint256 amountPerPayment;
        uint256 intervalSeconds;
        uint256 nextDue;
        uint256 startTime;
        uint256 paymentsMade;
        uint256 totalPaid;
        uint256 maxPayments;
        uint256 budget;
        bool active;
        bool paused;
    }

    /// @notice SPACE ID Agent ID contract on BNB Chain (ERC-721, non-transferable).
    address public immutable agentId;

    uint256 public nextPlanId;
    mapping(uint256 => Plan) public plans;

    bool private _locked;

    event PlanCreated(
        uint256 indexed planId,
        address indexed payer,
        address indexed payee,
        address token,
        uint256 amountPerPayment,
        uint256 intervalSeconds,
        uint256 startTime,
        uint256 maxPayments,
        uint256 budget
    );
    event PaymentExecuted(
        uint256 indexed planId,
        address indexed executor,
        uint256 amount,
        uint256 paymentsMade,
        uint256 nextDue
    );
    event PlanCancelled(uint256 indexed planId, address indexed payer);
    event PlanPaused(uint256 indexed planId, address indexed payer);
    event PlanResumed(uint256 indexed planId, address indexed payer);

    modifier nonReentrant() {
        require(!_locked, "REENTRANCY");
        _locked = true;
        _;
        _locked = false;
    }

    /// @param agentId_ SPACE ID Agent ID contract address (BNB Chain: 0x60b9262456de011f7d15a54cdd8c48baaa8b022f).
    constructor(address agentId_) {
        if (agentId_ == address(0)) revert ZeroAddress();
        agentId = agentId_;
    }

    /// @notice Whether an address holds an Agent ID (balanceOf > 0 on the Agent ID contract).
    function holdsAgentId(address account) public view returns (bool) {
        return IAgentID(agentId).balanceOf(account) > 0;
    }

    /// @notice Returns full details for a recurring payment plan
    /// @param planId ID of the plan to query
    function getPlan(uint256 planId) external view returns (Plan memory) {
        if (plans[planId].payer == address(0)) revert PlanNotFound();
        return plans[planId];
    }

    /// @notice Creates a new recurring payment plan. Caller MUST hold an Agent ID.
    /// @dev Revocable-approval model: payer creates schedule without depositing funds; must approve token allowance separately.
    /// @param token ERC-20 token address used for payment (e.g. BSC USDT 0x55d398326f99059fF775485246999027B3197955)
    /// @param payee Receiver address for recurring payments
    /// @param amountPerPayment Token amount per recurring interval
    /// @param intervalSeconds Duration between payments in seconds
    /// @param startTime Unix timestamp when payments become eligible (0 defaults to block.timestamp; a past value means the first payment is due immediately)
    /// @param maxPayments Total payments allowed (0 = unlimited)
    /// @param budget Cumulative spending limit in tokens (0 = unlimited)
    /// @return planId Unique ID of created payment plan
    function createPlan(
        address token,
        address payee,
        uint256 amountPerPayment,
        uint256 intervalSeconds,
        uint256 startTime,
        uint256 maxPayments,
        uint256 budget
    ) external nonReentrant returns (uint256 planId) {
        if (!holdsAgentId(msg.sender)) revert NotAgentIdHolder();
        if (token == address(0)) revert ZeroAddress();
        if (payee == address(0)) revert ZeroAddress();
        if (amountPerPayment == 0) revert ZeroAmount();
        if (intervalSeconds == 0) revert ZeroInterval();

        if (startTime == 0) {
            startTime = block.timestamp;
        }
        // A startTime in the past is allowed: the first payment is simply
        // due immediately (nextDue = startTime). This avoids spurious
        // reverts when the plan is mined a few seconds after creation.

        planId = nextPlanId++;
        plans[planId] = Plan({
            payer: msg.sender,
            payee: payee,
            token: token,
            amountPerPayment: amountPerPayment,
            intervalSeconds: intervalSeconds,
            nextDue: startTime,
            startTime: startTime,
            paymentsMade: 0,
            totalPaid: 0,
            maxPayments: maxPayments,
            budget: budget,
            active: true,
            paused: false
        });

        emit PlanCreated(
            planId,
            msg.sender,
            payee,
            token,
            amountPerPayment,
            intervalSeconds,
            startTime,
            maxPayments,
            budget
        );
    }

    /// @notice Executes a due payment for a given plan
    /// @dev Revocable-approval model: pulls funds directly from payer balance using ERC-20 transferFrom. Anyone can invoke (keepers, payee, payer).
    /// @param planId ID of payment plan to execute
    function executePayment(uint256 planId) external nonReentrant {
        Plan storage plan = plans[planId];
        if (plan.payer == address(0)) revert PlanNotFound();
        if (!plan.active || plan.paused) revert NotActive();
        if (block.timestamp < plan.nextDue) revert NotDue();
        if (plan.maxPayments != 0 && plan.paymentsMade >= plan.maxPayments) revert MaxPaymentsReached();
        if (plan.budget != 0 && plan.totalPaid + plan.amountPerPayment > plan.budget) revert BudgetExceeded();

        IERC20 token = IERC20(plan.token);
        if (token.allowance(plan.payer, address(this)) < plan.amountPerPayment) revert InsufficientAllowance();
        if (token.balanceOf(plan.payer) < plan.amountPerPayment) revert InsufficientBalance();

        plan.paymentsMade++;
        plan.totalPaid += plan.amountPerPayment;
        plan.nextDue += plan.intervalSeconds;

        bool ok = token.transferFrom(plan.payer, plan.payee, plan.amountPerPayment);
        if (!ok) revert TransferFailed();

        emit PaymentExecuted(planId, msg.sender, plan.amountPerPayment, plan.paymentsMade, plan.nextDue);
    }

    /// @notice Permanently cancels a payment plan
    /// @param planId ID of payment plan to cancel
    function cancelPlan(uint256 planId) external {
        if (plans[planId].payer == address(0)) revert PlanNotFound();
        if (msg.sender != plans[planId].payer) revert NotPayer();

        plans[planId].active = false;
        emit PlanCancelled(planId, msg.sender);
    }

    /// @notice Temporarily pauses execution of a payment plan
    /// @param planId ID of payment plan to pause
    function pausePlan(uint256 planId) external {
        if (plans[planId].payer == address(0)) revert PlanNotFound();
        if (msg.sender != plans[planId].payer) revert NotPayer();
        if (!plans[planId].active) revert NotActive();
        if (plans[planId].paused) revert AlreadyPaused();

        plans[planId].paused = true;
        emit PlanPaused(planId, msg.sender);
    }

    /// @notice Unpauses a previously paused payment plan
    /// @param planId ID of payment plan to resume
    function resumePlan(uint256 planId) external {
        if (plans[planId].payer == address(0)) revert PlanNotFound();
        if (msg.sender != plans[planId].payer) revert NotPayer();
        if (!plans[planId].active) revert NotActive();
        if (!plans[planId].paused) revert NotPaused();

        plans[planId].paused = false;
        emit PlanResumed(planId, msg.sender);
    }

    /// @notice Checks if a plan is currently eligible for payment execution
    /// @param planId ID of payment plan to check
    /// @return True if eligible for execution right now, false otherwise
    function isDue(uint256 planId) external view returns (bool) {
        Plan storage plan = plans[planId];
        if (plan.payer == address(0) || !plan.active || plan.paused) return false;
        if (block.timestamp < plan.nextDue) return false;
        if (plan.maxPayments != 0 && plan.paymentsMade >= plan.maxPayments) return false;
        if (plan.budget != 0 && plan.totalPaid + plan.amountPerPayment > plan.budget) return false;
        return true;
    }

    /// @notice Calculates the number of whole payment intervals currently due
    /// @param planId ID of payment plan to query
    /// @return Number of payments eligible to be processed
    function dueCount(uint256 planId) external view returns (uint256) {
        Plan storage plan = plans[planId];
        if (plan.payer == address(0) || !plan.active || plan.paused) return 0;
        if (block.timestamp < plan.nextDue) return 0;
        if (plan.maxPayments != 0 && plan.paymentsMade >= plan.maxPayments) return 0;
        if (plan.budget != 0 && plan.totalPaid + plan.amountPerPayment > plan.budget) return 0;

        uint256 elapsed = 1 + (block.timestamp - plan.nextDue) / plan.intervalSeconds;

        if (plan.maxPayments != 0) {
            uint256 remainingPayments = plan.maxPayments - plan.paymentsMade;
            if (elapsed > remainingPayments) {
                elapsed = remainingPayments;
            }
        }

        if (plan.budget != 0) {
            uint256 remainingBudget = plan.budget > plan.totalPaid ? plan.budget - plan.totalPaid : 0;
            uint256 maxByBudget = remainingBudget / plan.amountPerPayment;
            if (elapsed > maxByBudget) {
                elapsed = maxByBudget;
            }
        }

        return elapsed;
    }
}
