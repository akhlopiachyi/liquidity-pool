// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract RewardLiquidityPool {
    using SafeMath for uint256;

    address public issuer;
    address public broker;
    uint256 public fixedPrice;
    uint256 public claimPeriod;
    IERC20 public discoToken;
    IERC20 public usdcToken;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public poolShares;
    mapping(address => uint256) public lastClaimed;
    mapping(address => bool) public approvedDecommission;
    uint256 public totalTokens;
    uint256 public totalCollected;
    uint256 public constant coolDownPeriod = 1 days;
    uint256 public constant windowLimit = 14 days;
    mapping(address => uint256) public unclaimedRewards;
    bool public buyTokensPaused;

    event TokensPurchased(address indexed user, uint256 amount, uint256 price);
    event ClaimedRewards(address indexed user, uint256 amount);
    event PoolDecommissionApproved(address indexed user);
    event PoolDecommissionExecuted(address indexed user, address indexed receiver, uint256 amount);

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Only issuer can call this function");
        _;
    }

    modifier onlyBroker() {
        require(msg.sender == broker, "Only broker can call this function");
        _;
    }

    modifier tokensNotPaused() {
        require(!buyTokensPaused, "Token purchases are paused");
        _;
    }

    constructor(
        address _discoToken,
        address _usdcToken,
        uint256 _fixedPrice,
        uint256 _claimPeriod
    ) {
        issuer = msg.sender;
        fixedPrice = _fixedPrice;
        claimPeriod = _claimPeriod * 1 days;
        discoToken = IERC20(_discoToken);
        usdcToken = IERC20(_usdcToken);
    }

    function buyTokens(uint256 _usdcAmount) external tokensNotPaused {
        require(_usdcAmount > 0, "USDC value must be greater than 0");
        require(!buyTokensPaused, "Token purchases are paused");

        usdcToken.transferFrom(msg.sender, address(this), _usdcAmount);
        uint256 tokens = _usdcAmount / fixedPrice;

        require(tokens > 0, "Insufficient funds for purchase");

        balances[msg.sender] += tokens;
        poolShares[msg.sender] += _usdcAmount;
        totalTokens += tokens;
        totalCollected += _usdcAmount;
        emit TokensPurchased(msg.sender, tokens, fixedPrice);

        // Pause token purchases if the amount of USDC token in contract is equal to DISCO token amount * fixedPrice
        if (totalCollected >= discoToken.balanceOf(address(this)).mul(fixedPrice)) {
            buyTokensPaused = true;
        }
    }

    function claimRewards() external {
        require(balances[msg.sender] > 0, "No tokens to claim rewards for");
        require(block.timestamp >= lastClaimed[msg.sender] + coolDownPeriod, "Cooldown period has not passed");

        uint256 rewards = calculateRewards(msg.sender);
        unclaimedRewards[msg.sender] = 0;
        lastClaimed[msg.sender] = block.timestamp;

        if (rewards > 0) {
            discoToken.transfer(msg.sender, rewards);
            emit ClaimedRewards(msg.sender, rewards);
        }
    }

    function calculateRewards(address user) internal view returns (uint256) {
        uint256 daysSinceLastClaim = (block.timestamp - lastClaimed[user]) / coolDownPeriod;
        uint256 claimableAmount = (balances[user] * balances[issuer]) / (claimPeriod * poolShares[user]);

        return claimableAmount * daysSinceLastClaim;
    }

    function decommissionPool() external {
        require(approvedDecommission[msg.sender] == false, "Decommission already approved");
        approvedDecommission[msg.sender] = true;
        emit PoolDecommissionApproved(msg.sender);
    }

    function withdrawTokens(address to) external onlyIssuer {
        uint256 totalAssets = address(this).balance;
        usdcToken.transfer(to, totalAssets);

        emit PoolDecommissionExecuted(msg.sender, issuer, totalAssets);
    }

    function withdrawUnclaimedRewards() external {
        require(block.timestamp <= lastClaimed[msg.sender] + windowLimit, "Window limit exceeded for unclaimed rewards");
        uint256 rewards = unclaimedRewards[msg.sender];
        unclaimedRewards[msg.sender] = 0;
        discoToken.transfer(msg.sender, rewards);
    }
}
