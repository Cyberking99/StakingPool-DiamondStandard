// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../contracts/facets/KingStakingFacet.sol";
import "../contracts/KingToken.sol";
import "../contracts/KingCollections.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";

contract KingStakingPoolTest is Test {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

    KingToken kingToken;
    KingCollections kingCollections;
    KingStakingPool stakingPool;

    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        kingToken = new KingToken();
        kingCollections = new KingCollections();
        
        stakingPool = new KingStakingPool();
    }

    function testAddPool() public {
        vm.startPrank(owner);
        stakingPool.addPool("Test Pool", address(kingToken), address(kingCollections), 1e18, 86400);
        vm.stopPrank();
        
        (string memory poolName, address stakingToken, address rewardToken, uint256 rewardRate, uint256 stakingTime, uint256 totalStaked) = stakingPool.getPool(1);
        assertEq(poolName, "Test Pool");
        assertEq(stakingToken, address(kingToken));
    }

    function testStake() public {
        vm.startPrank(owner);
        stakingPool.addPool("Test Pool", address(kingToken), address(kingCollections), 1e18, 86400);

        kingToken.mint(user1, 100 ether);
        vm.stopPrank();

        vm.prank(user1);
        kingToken.approve(address(stakingPool), 10 ether);
        
        vm.prank(user1);
        stakingPool.stake(1, 10 ether);

        uint256 stakedBalance = stakingPool.getStakedBalance(1, user1);
        assertEq(stakedBalance, 10 ether);
    }

    function testWithdrawAfterMaturity() public {
        vm.startPrank(owner);
        stakingPool.addPool("Test Pool", address(kingToken), address(kingCollections), 1e18, 86400);

        kingToken.mint(user1, 100 ether);
        vm.stopPrank();

        vm.prank(user1);
        kingToken.approve(address(stakingPool), 10 ether);
        
        vm.prank(user1);
        stakingPool.stake(1, 10 ether);

        vm.warp(block.timestamp + 86400);
        
        vm.prank(user1);
        stakingPool.withdraw(1, 10 ether);

        uint256 stakedBalance = stakingPool.getStakedBalance(1, user1);
        assertEq(stakedBalance, 0);
    }

    function testCalculateReward() public {
        vm.startPrank(owner);
        stakingPool.addPool("Test Pool", address(kingToken), address(kingCollections), 1e18, 86400);

        kingToken.mint(user1, 100 ether);
        vm.stopPrank();

        vm.prank(user1);
        kingToken.approve(address(stakingPool), 10 ether);
        
        vm.prank(user1);
        stakingPool.stake(1, 10 ether);

        vm.warp(block.timestamp + 43200);

        uint256 reward = stakingPool.calculateReward(1, user1);
        assert(reward > 0);
    }
}
