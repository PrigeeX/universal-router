// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {V2SwapRouter} from '../modules/uniswap/v2/V2SwapRouter.sol';
import {V3SwapRouter} from '../modules/uniswap/v3/V3SwapRouter.sol';
import {BytesLib} from '../modules/uniswap/v3/BytesLib.sol';
import {Payments} from '../modules/Payments.sol';
import {PaymentsImmutables} from '../modules/PaymentsImmutables.sol';
import {NFTImmutables} from '../modules/NFTImmutables.sol';
import {Callbacks} from '../base/Callbacks.sol';
import {Commands} from '../libraries/Commands.sol';
import {LockAndMsgSender} from './LockAndMsgSender.sol';
import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';
import {IERC20} from '@openzeppelin/contracts-v4/token/ERC20/IERC20.sol';

/// @title Decodes and Executes Commands
/// @notice Called by PrigeeXUniversalRouter to decode and execute a single command.
///         NFT-marketplace dispatch cases have been removed; only V2/V3 swap,
///         Permit2, and payment commands remain.
abstract contract Dispatcher is NFTImmutables, Payments, V2SwapRouter, V3SwapRouter, Callbacks, LockAndMsgSender {
    using BytesLib for bytes;

    error InvalidCommandType(uint256 commandType);
    error BalanceTooLow();

    function dispatch(bytes1 commandType, bytes calldata inputs) internal returns (bool success, bytes memory output) {
        uint256 command = uint8(commandType & Commands.COMMAND_TYPE_MASK);

        success = true;

        if (command < Commands.SECOND_IF_BOUNDARY) {
            // 0x00 <= command < 0x08
            if (command < Commands.FIRST_IF_BOUNDARY) {
                if (command == Commands.V3_SWAP_EXACT_IN) {
                    address recipient;
                    uint256 amountIn;
                    uint256 amountOutMin;
                    bool payerIsUser;
                    assembly {
                        recipient := calldataload(inputs.offset)
                        amountIn := calldataload(add(inputs.offset, 0x20))
                        amountOutMin := calldataload(add(inputs.offset, 0x40))
                        payerIsUser := calldataload(add(inputs.offset, 0x80))
                    }
                    bytes calldata path = inputs.toBytes(3);
                    address payer = payerIsUser ? lockedBy : address(this);
                    v3SwapExactInput(map(recipient), amountIn, amountOutMin, path, payer);
                } else if (command == Commands.V3_SWAP_EXACT_OUT) {
                    address recipient;
                    uint256 amountOut;
                    uint256 amountInMax;
                    bool payerIsUser;
                    assembly {
                        recipient := calldataload(inputs.offset)
                        amountOut := calldataload(add(inputs.offset, 0x20))
                        amountInMax := calldataload(add(inputs.offset, 0x40))
                        payerIsUser := calldataload(add(inputs.offset, 0x80))
                    }
                    bytes calldata path = inputs.toBytes(3);
                    address payer = payerIsUser ? lockedBy : address(this);
                    v3SwapExactOutput(map(recipient), amountOut, amountInMax, path, payer);
                } else if (command == Commands.PERMIT2_TRANSFER_FROM) {
                    address token;
                    address recipient;
                    uint160 amount;
                    assembly {
                        token := calldataload(inputs.offset)
                        recipient := calldataload(add(inputs.offset, 0x20))
                        amount := calldataload(add(inputs.offset, 0x40))
                    }
                    permit2TransferFrom(token, lockedBy, map(recipient), amount);
                } else if (command == Commands.PERMIT2_PERMIT_BATCH) {
                    (IAllowanceTransfer.PermitBatch memory permitBatch,) =
                        abi.decode(inputs, (IAllowanceTransfer.PermitBatch, bytes));
                    bytes calldata data = inputs.toBytes(1);
                    PERMIT2.permit(lockedBy, permitBatch, data);
                } else if (command == Commands.SWEEP) {
                    address token;
                    address recipient;
                    uint160 amountMin;
                    assembly {
                        token := calldataload(inputs.offset)
                        recipient := calldataload(add(inputs.offset, 0x20))
                        amountMin := calldataload(add(inputs.offset, 0x40))
                    }
                    Payments.sweep(token, map(recipient), amountMin);
                } else if (command == Commands.TRANSFER) {
                    address token;
                    address recipient;
                    uint256 value;
                    assembly {
                        token := calldataload(inputs.offset)
                        recipient := calldataload(add(inputs.offset, 0x20))
                        value := calldataload(add(inputs.offset, 0x40))
                    }
                    Payments.pay(token, map(recipient), value);
                } else if (command == Commands.PAY_PORTION) {
                    address token;
                    address recipient;
                    uint256 bips;
                    assembly {
                        token := calldataload(inputs.offset)
                        recipient := calldataload(add(inputs.offset, 0x20))
                        bips := calldataload(add(inputs.offset, 0x40))
                    }
                    Payments.payPortion(token, map(recipient), bips);
                } else {
                    revert InvalidCommandType(command);
                }
            // 0x08 <= command < 0x10
            } else {
                if (command == Commands.V2_SWAP_EXACT_IN) {
                    address recipient;
                    uint256 amountIn;
                    uint256 amountOutMin;
                    bool payerIsUser;
                    assembly {
                        recipient := calldataload(inputs.offset)
                        amountIn := calldataload(add(inputs.offset, 0x20))
                        amountOutMin := calldataload(add(inputs.offset, 0x40))
                        payerIsUser := calldataload(add(inputs.offset, 0x80))
                    }
                    address[] calldata path = inputs.toAddressArray(3);
                    address payer = payerIsUser ? lockedBy : address(this);
                    v2SwapExactInput(map(recipient), amountIn, amountOutMin, path, payer);
                } else if (command == Commands.V2_SWAP_EXACT_OUT) {
                    address recipient;
                    uint256 amountOut;
                    uint256 amountInMax;
                    bool payerIsUser;
                    assembly {
                        recipient := calldataload(inputs.offset)
                        amountOut := calldataload(add(inputs.offset, 0x20))
                        amountInMax := calldataload(add(inputs.offset, 0x40))
                        payerIsUser := calldataload(add(inputs.offset, 0x80))
                    }
                    address[] calldata path = inputs.toAddressArray(3);
                    address payer = payerIsUser ? lockedBy : address(this);
                    v2SwapExactOutput(map(recipient), amountOut, amountInMax, path, payer);
                } else if (command == Commands.PERMIT2_PERMIT) {
                    IAllowanceTransfer.PermitSingle calldata permitSingle;
                    assembly {
                        permitSingle := inputs.offset
                    }
                    bytes calldata data = inputs.toBytes(6);
                    PERMIT2.permit(lockedBy, permitSingle, data);
                } else if (command == Commands.WRAP_ETH) {
                    address recipient;
                    uint256 amountMin;
                    assembly {
                        recipient := calldataload(inputs.offset)
                        amountMin := calldataload(add(inputs.offset, 0x20))
                    }
                    Payments.wrapETH(map(recipient), amountMin);
                } else if (command == Commands.UNWRAP_WETH) {
                    address recipient;
                    uint256 amountMin;
                    assembly {
                        recipient := calldataload(inputs.offset)
                        amountMin := calldataload(add(inputs.offset, 0x20))
                    }
                    Payments.unwrapWETH9(map(recipient), amountMin);
                } else if (command == Commands.PERMIT2_TRANSFER_FROM_BATCH) {
                    (IAllowanceTransfer.AllowanceTransferDetails[] memory batchDetails) =
                        abi.decode(inputs, (IAllowanceTransfer.AllowanceTransferDetails[]));
                    permit2TransferFrom(batchDetails, lockedBy);
                } else if (command == Commands.BALANCE_CHECK_ERC20) {
                    address owner;
                    address token;
                    uint256 minBalance;
                    assembly {
                        owner := calldataload(inputs.offset)
                        token := calldataload(add(inputs.offset, 0x20))
                        minBalance := calldataload(add(inputs.offset, 0x40))
                    }
                    success = (IERC20(token).balanceOf(owner) >= minBalance);
                    if (!success) output = abi.encodePacked(BalanceTooLow.selector);
                } else {
                    revert InvalidCommandType(command);
                }
            }
        } else {
            // 0x10–0x20 are removed NFT commands — revert cleanly
            if (command == Commands.EXECUTE_SUB_PLAN) {
                bytes calldata _commands = inputs.toBytes(0);
                bytes[] calldata _inputs = inputs.toBytesArray(1);
                (success, output) =
                    (address(this)).call(abi.encodeWithSelector(Dispatcher.execute.selector, _commands, _inputs));
            } else {
                revert InvalidCommandType(command);
            }
        }
    }

    function execute(bytes calldata commands, bytes[] calldata inputs) external payable virtual;
}
