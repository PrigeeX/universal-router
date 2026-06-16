// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

struct UniswapParameters {
    address v2Factory;
    address v3Factory;
    bytes32 pairInitCodeHash;
    bytes32 poolInitCodeHash;
}

contract UniswapImmutables {
    /// @dev The address of PrigeeXV2Factory
    address internal immutable PRIGEEX_V2_FACTORY;

    /// @dev The PrigeeXV2Pair initcodehash
    bytes32 internal immutable PRIGEEX_V2_PAIR_INIT_CODE_HASH;

    /// @dev The address of PrigeeXV3Factory
    address internal immutable PRIGEEX_V3_FACTORY;

    /// @dev The PrigeeXV3Pool initcodehash
    bytes32 internal immutable PRIGEEX_V3_POOL_INIT_CODE_HASH;

    constructor(UniswapParameters memory params) {
        PRIGEEX_V2_FACTORY = params.v2Factory;
        PRIGEEX_V2_PAIR_INIT_CODE_HASH = params.pairInitCodeHash;
        PRIGEEX_V3_FACTORY = params.v3Factory;
        PRIGEEX_V3_POOL_INIT_CODE_HASH = params.poolInitCodeHash;
    }
}
