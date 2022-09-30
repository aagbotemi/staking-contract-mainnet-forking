// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "solmate/tokens/ERC20.sol";

contract Staking {
    address owner;
    uint40 factor = 1e11;
    uint16 delta = 3854;
    address BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    struct UserData {
        uint216 stakedAmount;
        uint40 lastTimeStaked;
    }

    mapping(address => UserData) userData;
    //check-effects-interact
    event Staked(address indexed user, uint216 amount);
    event Withdrawn(address indexed user, uint216 amount);
    // event InterestPaid(address indexed user, uint216 amount);
    event InterestCompounded(address indexed user, uint216 amount);

    constructor(address _owner) {
        owner = _owner;
    }

    function stake(uint256 _amount) external {
        assert(ERC20(owner).transferFrom(msg.sender, address(this), _amount));
        UserData storage u = userData[msg.sender];
        assert(BAYU(BAYC).balanceOf(msg.sender) > 0);
        if (u.stakedAmount > 0) {
            uint256 currentRewards = getRewards(msg.sender);
            u.stakedAmount += uint216(currentRewards);
            emit InterestCompounded(msg.sender, uint216(currentRewards));
        }
        //update storage
        u.stakedAmount += uint216(_amount);
        u.lastTimeStaked = uint40(block.timestamp);
        emit Staked(msg.sender, uint216(_amount));
    }

    function unstake(uint256 _amount) external {
        UserData storage u = userData[msg.sender];
        assert(u.stakedAmount >= _amount);
        uint216 amountToSend = uint216(_amount);
        amountToSend += getRewards(msg.sender);
        //update storage
        u.stakedAmount -= uint216(_amount);
        u.lastTimeStaked = uint40(block.timestamp);
        ERC20(owner).transfer(msg.sender, amountToSend);
        emit Withdrawn(msg.sender, amountToSend);
    }

    function getUser(address _user) public view returns (UserData memory u) {
        u = userData[_user];
    }

    function getRewards(address _user)
        internal
        view
        returns (uint216 interest__)
    {
        UserData memory u = userData[_user];
        if (u.stakedAmount > 0) {
            uint216 currentAmount = u.stakedAmount;
            uint40 lastTime = u.lastTimeStaked;
            uint40 duration = uint40(block.timestamp) - lastTime;
            interest__ = uint216(delta * duration * currentAmount);
            interest__ /= uint216(factor);
        }
    }
}

interface BAYU {
    function balanceOf(address owner) external view returns (uint256);
}
