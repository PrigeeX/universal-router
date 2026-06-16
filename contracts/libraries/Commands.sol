// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Commands
/// @notice Command flags used to decode commands sent to PrigeeXUniversalRouter.
///         NFT-marketplace commands (Seaport, LooksRare, X2Y2, NFTX, Sudoswap,
///         CryptoPunks, Foundation, Element, NFT20) have been removed — PrigeeX
///         is a token DEX and has no use for them.
library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    // ── Block 1 (0x00–0x07): V3 swaps + permit2 + payments ──────────────────
    uint256 constant V3_SWAP_EXACT_IN = 0x00;
    uint256 constant V3_SWAP_EXACT_OUT = 0x01;
    uint256 constant PERMIT2_TRANSFER_FROM = 0x02;
    uint256 constant PERMIT2_PERMIT_BATCH = 0x03;
    uint256 constant SWEEP = 0x04;
    uint256 constant TRANSFER = 0x05;
    uint256 constant PAY_PORTION = 0x06;
    // 0x07 reserved

    uint256 constant FIRST_IF_BOUNDARY = 0x08;

    // ── Block 2 (0x08–0x0f): V2 swaps + ETH wrap/unwrap ─────────────────────
    uint256 constant V2_SWAP_EXACT_IN = 0x08;
    uint256 constant V2_SWAP_EXACT_OUT = 0x09;
    uint256 constant PERMIT2_PERMIT = 0x0a;
    uint256 constant WRAP_ETH = 0x0b;
    uint256 constant UNWRAP_WETH = 0x0c;
    uint256 constant PERMIT2_TRANSFER_FROM_BATCH = 0x0d;
    uint256 constant BALANCE_CHECK_ERC20 = 0x0e;
    // 0x0f reserved

    uint256 constant SECOND_IF_BOUNDARY = 0x10;

    // 0x10–0x20: removed (NFT marketplace commands)

    // ── Block 3 (0x21): sub-plan execution ───────────────────────────────────
    uint256 constant EXECUTE_SUB_PLAN = 0x21;
    // 0x22–0x3f reserved
}
