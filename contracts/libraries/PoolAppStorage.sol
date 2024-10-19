// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

library PoolAppStorage {

    struct Pool {
        string poolName;
        address stakingToken;
        address rewardToken;
        uint256 rewardRate;
        uint stakingTime;
        uint256 totalStaked;
    }
    
    struct Layout {
        mapping(uint256 => Pool) pools;
    }
}