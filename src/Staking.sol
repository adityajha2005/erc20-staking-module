// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";    
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract Staking is Ownable, Pausable, ReentrancyGuard{
    struct Staker{
        uint256 amountStaked;
        uint256 rewardDebt;  
        uint256 lastUpdated; //timestamp of last interaction
    }
    mapping(address => Staker) public stakers;
    using SafeERC20 for IERC20;
    IERC20 public token;

    constructor(address _token) Ownable(msg.sender){
        token=IERC20(_token);
    }
    uint256 public rewardRate = 1e12;
    uint256 public lockDuration = 7 days;

    event Staked(address indexed user, uint256 amount);
    // event Claimed(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);
    event LockDuration(uint256 LockDuration);
    function stake(uint256 amount) public whenNotPaused{
        require(amount>0,"Amount must be greater than 0");
        require(stakers[msg.sender].amountStaked==0,"Already staked");
        token.safeTransferFrom(msg.sender,address(this),amount);
        stakers[msg.sender].amountStaked=amount;
        stakers[msg.sender].lastUpdated=block.timestamp;
        stakers[msg.sender].rewardDebt=0;
    }
    function calculateReward(address _user) public view returns(uint256){
        Staker memory user = stakers[_user];
        if(user.amountStaked==0){
            return 0; //no rewards if staked 0
        }
        uint256 timeStaked = block.timestamp - user.lastUpdated; //current time - last updated time
        uint256 pendingReward = (user.amountStaked * timeStaked * rewardRate) / 1e12;
        return pendingReward;
    }
    function claimReward() public nonReentrant{
        require(stakers[msg.sender].amountStaked>0,"Not staked");//check if staked
        uint256 pendingReward = calculateReward(msg.sender); //calculateReward
        require(pendingReward>0,"No rewards to claim");
        token.safeTransfer(msg.sender, pendingReward); 
        stakers[msg.sender].lastUpdated=block.timestamp;
        stakers[msg.sender].rewardDebt+=pendingReward; //total claimed reward
        emit ClaimReward(msg.sender, pendingReward);
    }
    function withdraw() public nonReentrant{
        Staker storage user = stakers[msg.sender];
        require(user.amountStaked>0,"Not staked");
        require(block.timestamp - user.lastUpdated >= lockDuration, "Not enough time passed");
        // claimReward();
        uint256 stakedAmount = user.amountStaked;
        token.safeTransfer(msg.sender, stakedAmount); //transfer staked amount
        emit Withdraw(msg.sender, stakedAmount);
        // user.amountStaked=0; //amount staked to 0 after emitting event
        delete stakers[msg.sender]; //delete staker from mapping to save gas
    }
    function pause() external onlyOwner{
        _pause();
    }
    function unpause() external onlyOwner{
        _unpause();
    }
    function setRewardRate(uint256 _rewardRate) external onlyOwner{
        rewardRate = _rewardRate;
    }
    function setLockDuration(uint256 _lockDuration) external onlyOwner{
        lockDuration = _lockDuration;
        emit LockDuration(_lockDuration);
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner{
        require(_token!=address(token), "Cannot withdraw staking token");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}