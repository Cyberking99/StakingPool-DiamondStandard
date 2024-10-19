// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "../lib/forge-std/src/Script.sol";
import "../contracts/facets/KingStakingFacet.sol";
import "../contracts/KingToken.sol";
import "../contracts/KingCollections.sol";

contract KingStakingPoolInteraction is Script {
    KingStakingPool public stakingPool;
    KingToken public kingToken;
    KingCollections public kingCollections;

    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() public {
        vm.startBroadcast(owner);
        
        kingToken = new KingToken();
        kingCollections = new KingCollections();
        stakingPool = new KingStakingPool();
        
        stakingPool.addPool("Test Pool", address(kingToken), address(kingCollections), 1e18, 86400);
        
        kingToken.mint(user, 100 ether);
        
        vm.stopBroadcast();
        
        vm.startBroadcast(user);
        kingToken.approve(address(stakingPool), 10 ether);
        vm.stopBroadcast();
        
        vm.startBroadcast(user);
        stakingPool.stake(1, 10 ether);
        vm.stopBroadcast();
        
        vm.warp(block.timestamp + 86400 + 1);
        
        vm.startBroadcast(user);
        stakingPool.withdraw(1, 10 ether);
        vm.stopBroadcast();
        
        uint256 stakedBalance = stakingPool.getStakedBalance(1, user);
        require(stakedBalance == 0, "Staked balance should be zero after withdrawal");

        // vm.startBroadcast(user);
        // stakingPool.claimReward(1);
        // vm.stopBroadcast();
    }
}
