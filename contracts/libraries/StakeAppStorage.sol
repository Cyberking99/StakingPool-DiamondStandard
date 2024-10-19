// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

library StakeAppStorage {

    event Staked(address indexed user, uint256 poolId, uint256 amount);
    event Withdrawn(address indexed user, uint256 poolId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 stakeId, uint256 amount);

    struct Staker {
        uint stakeId;
        uint poolId;
        uint amountStaked;
        uint maturityTime;
    }

    struct Layout {
        mapping(address => mapping(uint256 => Staker)) stakers;
        address owner;
        uint256 rewardNFTIdCounter;
        uint256 nextPoolId;
        uint256 nextStakeId;
        
        bool locked;
    }
}