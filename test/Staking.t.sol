// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "./mock/MockERC20.sol";

contract StakingTest is Test {
    Staking public staking;
    MockERC20 public token;

    function setUp() public {
        token = new MockERC20();
        staking = new Staking(address(token));
        staking.setRewardRate(1);
        token.approve(address(staking), type(uint256).max);
    }

    function test_stake() public {
        uint256 amount = 1 ether;
        staking.stake(amount);
        (uint256 amountStaked,,) = staking.stakers(address(this));
        assertEq(amountStaked, amount);
    }

    function test_calculateReward() public {
        uint256 amount = 1 ether;
        staking.stake(amount);

        vm.warp(block.timestamp + 1 days);
        uint256 reward = staking.calculateReward(address(this));
        assertEq(reward, 86400000000); 
        staking.claimReward();
        (uint256 amountStaked, uint256 rewardDebt, uint256 lastUpdated) = staking.stakers(address(this));
        assertEq(amountStaked, 1 ether);
        assertEq(rewardDebt, reward);
        assertEq(lastUpdated, block.timestamp);
    }

    function test_claimReward() public{
        uint256 amount = 1 ether;
        staking.stake(amount);
        vm.warp(block.timestamp + 1 days);
        uint256 reward = staking.calculateReward(address(this));
        uint256 initialBalance = token.balanceOf(address(this));
        staking.claimReward();
        (uint256 amountStaked, uint256 rewardDebt, uint256 lastUpdated)=staking.stakers(address(this));
        assertEq(amountStaked,1 ether);
        assertEq(rewardDebt,reward);
        assertEq(lastUpdated,block.timestamp);
        uint256 finalBalance = reward+initialBalance;
        assertEq(token.balanceOf(address(this)),finalBalance);
    }

    function test_withdraw() public{
        uint256 amount = 1 ether;
        staking.stake(amount);
        vm.warp(block.timestamp + 8 days);
        uint256 reward = staking.calculateReward(address(this));
        // staking.claimReward();
        uint256 initialBalance = token.balanceOf(address(this));
        staking.withdraw();
        uint256 finalBalance = token.balanceOf(address(this));
        assertEq(finalBalance - initialBalance, amount);
    }
}
