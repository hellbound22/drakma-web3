// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DrakmaFiWeb3 {
    // Self
    address manager;
    int stakeBucket;
    int collateralHoldRef;
    int supplyRef;
    uint8 ltv = 50;
    uint8 smf = 100; //  10% (100 / 1000 = 0,1)

    struct endUser {
        int wallet;
        int stake;
        int loanValue;
        uint256 lastLoanTimestamp;
        int collateral;
        bool sharkLock; // Blocks any actions until debts are repayed
    }

    mapping(address => endUser) endUserMap;

    constructor () {
        manager = msg.sender;
    }

    function modstakeBucket(int delta) public returns (int) {
        stakeBucket += delta;
        return stakeBucket;
    }

    function checkSysState() public view returns (address, int, uint8) {
        return (manager, stakeBucket, ltv);
    }

    function checkEndUser(address user) public view returns (endUser memory e) {
        return endUserMap[user];
    }

    function authority(address keycard) private view returns (bool) {
        return keycard == manager;
    }

    function newEndUser(address endUserAddress, int initialWallet) public {
        require(authority(msg.sender));
        // TODO: Need to check and require that address is not already mapped

        endUserMap[endUserAddress] = endUser(initialWallet, 0, 0, 0, 0, false);
        supplyRef += initialWallet;
    }

    function stakeEndUser(address endUserAddress, int stakeValue) public {
        require(authority(msg.sender));
        endUser memory user = endUserMap[endUserAddress];
        require(user.wallet < stakeValue);

        endUserMap[endUserAddress].wallet -= stakeValue;
        stakeBucket += stakeValue;
    }

    function loanEndUser(address endUserAddress, int loanDesired) public {
        endUser memory user = endUserMap[endUserAddress];
        require(!user.sharkLock);

        int finalLoanCost = loanDesired * 100 / 50;
        require(finalLoanCost <= user.collateral);
        require(stakeBucket > loanDesired);

        endUserMap[endUserAddress].wallet += loanDesired;
        stakeBucket -= loanDesired;
        endUserMap[endUserAddress].lastLoanTimestamp = block.timestamp;
        endUserMap[endUserAddress].sharkLock = true;
    }

    function addToWalletEndUser(address _user, int _value) public {
        endUserMap[_user].wallet += _value;
        supplyRef += _value;
    }

    function repayEndUser(address _user) public {
        require(endUserMap[_user].wallet >= endUserMap[_user].loanValue);

        int value = endUserMap[_user].loanValue;

        endUserMap[_user].wallet -= value;
        endUserMap[_user].loanValue = 0;
        endUserMap[_user].sharkLock = false;
    }

    function addCollateralEndUser(address endUserAddress, int collateralAmount) public {
        endUser memory user = endUserMap[endUserAddress];
        require(!user.sharkLock);

        require(collateralAmount <= user.wallet);

        endUserMap[endUserAddress].wallet -= collateralAmount;
        endUserMap[endUserAddress].collateral += collateralAmount;
        collateralHoldRef += collateralAmount;
    }
}
