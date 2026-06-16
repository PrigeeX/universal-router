// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {Constants} from '../libraries/Constants.sol';
import {PaymentsImmutables} from '../modules/PaymentsImmutables.sol';
import {IERC20} from '@openzeppelin/contracts-v4/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-v4/token/ERC20/utils/SafeERC20.sol';

/// @title Payments contract
/// @notice Performs various operations around the payment of ETH and tokens
abstract contract Payments is PaymentsImmutables {
    using SafeERC20 for IERC20;

    error InsufficientToken();
    error InsufficientETH();
    error InvalidBips();

    uint256 internal constant FEE_BIPS_BASE = 10_000;

    /// @notice Pays an amount of ETH or ERC20 to a recipient
    function pay(address token, address recipient, uint256 value) internal {
        if (token == Constants.ETH) {
            _transferETH(recipient, value);
        } else {
            if (value == Constants.CONTRACT_BALANCE) {
                value = IERC20(token).balanceOf(address(this));
            }
            IERC20(token).safeTransfer(recipient, value);
        }
    }

    /// @notice Pays a proportion of the contract's ETH or ERC20 to a recipient
    function payPortion(address token, address recipient, uint256 bips) internal {
        if (bips == 0 || bips > FEE_BIPS_BASE) revert InvalidBips();
        if (token == Constants.ETH) {
            uint256 balance = address(this).balance;
            uint256 amount = (balance * bips) / FEE_BIPS_BASE;
            _transferETH(recipient, amount);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 amount = (balance * bips) / FEE_BIPS_BASE;
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    /// @notice Sweeps all of the contract's ERC20 or ETH to an address
    function sweep(address token, address recipient, uint256 amountMinimum) internal {
        uint256 balance;
        if (token == Constants.ETH) {
            balance = address(this).balance;
            if (balance < amountMinimum) revert InsufficientETH();
            if (balance > 0) _transferETH(recipient, balance);
        } else {
            balance = IERC20(token).balanceOf(address(this));
            if (balance < amountMinimum) revert InsufficientToken();
            if (balance > 0) IERC20(token).safeTransfer(recipient, balance);
        }
    }

    /// @notice Wraps an amount of ETH into WETH
    function wrapETH(address recipient, uint256 amount) internal {
        if (amount == Constants.CONTRACT_BALANCE) {
            amount = address(this).balance;
        } else if (amount > address(this).balance) {
            revert InsufficientETH();
        }
        if (amount > 0) {
            WETH9.deposit{value: amount}();
            if (recipient != address(this)) {
                WETH9.transfer(recipient, amount);
            }
        }
    }

    /// @notice Unwraps all of the contract's WETH into ETH
    function unwrapWETH9(address recipient, uint256 amountMinimum) internal {
        uint256 value = WETH9.balanceOf(address(this));
        if (value < amountMinimum) revert InsufficientETH();
        if (value > 0) {
            WETH9.withdraw(value);
            if (recipient != address(this)) {
                _transferETH(recipient, value);
            }
        }
    }

    function _transferETH(address to, uint256 amount) private {
        (bool ok,) = to.call{value: amount}('');
        if (!ok) revert InsufficientETH();
    }
}
