// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "../../lib/forge-std/src/console2.sol";
import "../libraries/PoolAppStorage.sol";
import "../libraries/StakeAppStorage.sol";
import "../KingToken.sol";
import "../KingCollections.sol";

contract KingStakingPool {
    StakeAppStorage.Layout internal sl;
    PoolAppStorage.Layout internal pl;
    

    constructor() {
        sl.owner = msg.sender;
        sl.nextPoolId = 1;
        sl.nextStakeId = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == sl.owner, "Error: You are not the owner");
        _;
    }

    modifier noReentrant() {
        require(!sl.locked, "Error: Reentrancy detected");
        sl.locked = true;
        _;
        sl.locked = false;
    }

    function addPool(
        string memory poolName,
        address stakingToken,
        address rewardToken,
        uint256 rewardRate,
        uint stakingTime
    ) external onlyOwner {
        require(
            pl.pools[sl.nextPoolId].stakingToken == address(0),
            "Error: Pool already exists"
        );

        pl.pools[sl.nextPoolId] = PoolAppStorage.Pool({
            poolName: poolName,
            stakingToken: stakingToken,
            rewardToken: rewardToken,
            rewardRate: rewardRate,
            stakingTime: stakingTime,
            totalStaked: 0
        });

        sl.nextPoolId++;
    }

    function stake(uint256 _poolId, uint256 _amount) external noReentrant {
        PoolAppStorage.Pool storage pool = pl.pools[_poolId];
        require(pool.stakingToken != address(0), "Error: Pool doesn't exist");

        // Staker storage staker = stakers[msg.sender][_poolId];
        // if (staker.amountStaked == 0) {
        //     staker.maturityTime = block.timestamp;
        // }

        uint _maturityTime = pool.stakingTime + block.timestamp;

        KingToken(pool.stakingToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        StakeAppStorage.Staker memory newStake = StakeAppStorage.Staker({
            stakeId: sl.nextStakeId,
            poolId: _poolId,
            amountStaked: _amount,
            maturityTime: _maturityTime
        });

        sl.nextStakeId += 1;

        sl.stakers[msg.sender][_poolId] = newStake;

        pool.totalStaked += _amount;
        // staker.amountStaked += _amount;

        emit StakeAppStorage.Staked(msg.sender, _poolId, _amount);
    }

    function withdraw(uint256 poolId, uint256 amount) external noReentrant {
        StakeAppStorage.Staker storage staker = sl.stakers[msg.sender][poolId];

        require(
            staker.amountStaked >= amount,
            "Error: You did not stake up to that amount"
        );
        require(
            block.timestamp > staker.maturityTime,
            "Error: You can't withdraw yet"
        );

        // Update balances
        staker.amountStaked -= amount;
        pl.pools[poolId].totalStaked -= amount;

        // Transfer tokens to the user
        KingToken(pl.pools[poolId].stakingToken).transfer(msg.sender, amount);

        // If the staker has no more staked amount, delete their entry
        if (staker.amountStaked == 0) {
            delete sl.stakers[msg.sender][poolId];
        }

        emit StakeAppStorage.Withdrawn(msg.sender, poolId, amount);
    }

    function claimReward(uint256 poolId) public {
        StakeAppStorage.Staker storage staker = sl.stakers[msg.sender][poolId];
        uint256 reward = calculateReward(poolId, msg.sender);

        require(reward > 0, "Error: No rewards to claim");

        KingToken(pl.pools[poolId].rewardToken).transfer(msg.sender, reward);
        emit StakeAppStorage.RewardClaimed(msg.sender, staker.stakeId, reward);
    }

    function calculateReward(
        uint256 poolId,
        address stakerAddress
    ) public view returns (uint256) {
        PoolAppStorage.Pool storage pool = pl.pools[poolId];
        StakeAppStorage.Staker storage staker = sl.stakers[stakerAddress][
            poolId
        ];

        uint256 timeElapsed = (block.timestamp < staker.maturityTime)
            ? block.timestamp - (staker.maturityTime - pool.stakingTime)
            : staker.maturityTime - (staker.maturityTime - pool.stakingTime);

        uint256 reward = (timeElapsed * staker.amountStaked * pool.rewardRate) /
            1e18;

        return reward;
    }

    function getStakedBalance(
        uint256 poolId,
        address stakerAddress
    ) public view returns (uint256) {
        return sl.stakers[stakerAddress][poolId].amountStaked;
    }

    function getPool(
        uint256 poolId
    )
        external
        view
        returns (string memory, address, address, uint256, uint256, uint256)
    {
        PoolAppStorage.Pool storage pool = pl.pools[poolId];
        return (
            pool.poolName,
            pool.stakingToken,
            pool.rewardToken,
            pool.rewardRate,
            pool.stakingTime,
            pool.totalStaked
        );
    }
}
