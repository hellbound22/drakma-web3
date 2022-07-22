// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

contract DrakmaFiWeb3 {
    // Self
    address manager;
    uint256 stakeBucket;
    uint256 collateralHoldRef;
    uint256 supplyRef;
    uint8 ltv = 50;
    uint8 sdr = 100; //  Standard daily rate = 10% (100 / 1000 = 0,1)

    struct endUser {
        uint256 wallet;
        uint256 stake;
        uint256 loanValue;
        uint256 lastLoanTimestamp;
        uint256 collateral;
        bool sharkLock; // Blocks any actions until debts are repayed
    }

    mapping(address => endUser) endUserMap;

    constructor () {
        manager = msg.sender;
    }

    function modstakeBucket(uint256 delta) public returns (uint256) {
        stakeBucket += delta;
        return stakeBucket;
    }

    function checkSysState() public view returns (address, uint256, uint8) {
        return (manager, stakeBucket, ltv);
    }

    function checkEndUser(address user) public view returns (endUser memory e) {
        return endUserMap[user];
    }

    function authority(address keycard) private view returns (bool) {
        return keycard == manager;
    }

    function newEndUser(address endUserAddress, uint256 initialWallet) public {
        require(authority(msg.sender));
        // TODO: Need to check and require that address is not already mapped

        endUserMap[endUserAddress] = endUser(initialWallet, 0, 0, 0, 0, false);
        supplyRef += initialWallet;
    }

    function stakeEndUser(address endUserAddress, uint256 stakeValue) public {
        require(authority(msg.sender));
        endUser memory user = endUserMap[endUserAddress];
        require(user.wallet < stakeValue);

        endUserMap[endUserAddress].wallet -= stakeValue;
        stakeBucket += stakeValue;
    }

    function loanEndUser(address endUserAddress, uint256 loanDesired) public {
        endUser memory user = endUserMap[endUserAddress];
        require(!user.sharkLock);

        uint256 finalLoanCost = loanDesired * 100 / 50;
        require(finalLoanCost <= user.collateral);
        require(stakeBucket > loanDesired);

        endUserMap[endUserAddress].wallet += loanDesired;
        stakeBucket -= loanDesired;
        endUserMap[endUserAddress].lastLoanTimestamp = block.timestamp;
        endUserMap[endUserAddress].sharkLock = true;
    }

    function addToWalletEndUser(address _user, uint256 _value) public {
        endUserMap[_user].wallet += _value;
        supplyRef += _value;
    }

    function fee(uint _principal, uint _time) private pure returns (uint) {
        // TODO: define rate
        uint fator = 100;
        uint c = _principal * fator;
        uint t_juros = 10; // 0.1 * 100

        uint m = c*((1+t_juros)**_time);

        return m / fator / fator;
    }

    function repayEndUser(address _user) public {
        require(endUserMap[_user].wallet >= endUserMap[_user].loanValue);

        // TODO: aplly fee (intrest + gas cost + upstream operation cost)
        // Gas cost = get estimate from upstream app (update state of contract daily if necessary), calculate aprox cost using oracle
        // The 2 is temporary
        uint value = endUserMap[_user].loanValue + fee(endUserMap[_user].loanValue, 2);

        endUserMap[_user].wallet -= value;
        endUserMap[_user].loanValue = 0;
        endUserMap[_user].sharkLock = false;
    }

    function addCollateralEndUser(address endUserAddress, uint256 collateralAmount) public {
        endUser memory user = endUserMap[endUserAddress];
        require(!user.sharkLock);

        require(collateralAmount <= user.wallet);

        endUserMap[endUserAddress].wallet -= collateralAmount;
        endUserMap[endUserAddress].collateral += collateralAmount;
        collateralHoldRef += collateralAmount;
    }
}
