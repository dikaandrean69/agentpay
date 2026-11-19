// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Test-only mock of the SPACE ID Agent ID contract (ERC-721 balanceOf only).
contract MockAgentID {
    mapping(address => uint256) private _balances;

    function setBalance(address account, uint256 amount) external {
        _balances[account] = amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
}
