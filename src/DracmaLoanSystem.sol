// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DracmaLoanSystem {
    // Self
    address manager;
    int liquidityBucket;
    uint8 ltv = 50;

    struct endUser {
        int wallet;
        int stake;
        int stakeUsed;
        int collateral;
        bool sharkLock; // Blocks any actions until debts are repayed
    }

    mapping(address => endUser) endUserMap;

    constructor () {
        manager = msg.sender;
    }

    function modLiquidityBucket(int delta) public returns (int) {
        liquidityBucket += delta;
        return liquidityBucket;
    }

    function checkLiquidityBucket() public view returns (int) {
        return liquidityBucket;
    }

    function authority(address keycard) private view returns (bool){
        return keycard == manager;
    }

    function newEndUser(address endUserAddress, int initialWallet) public {
        require(authority(msg.sender));

        endUserMap[endUserAddress] = endUser(initialWallet, 0, 0, 0, false);
    }

    function stakeEndUser(address endUserAddress, int stakeValue) public {
        require(authority(msg.sender));
        endUser memory user = endUserMap[endUserAddress];
        require(user.wallet < stakeValue);

        endUserMap[endUserAddress].wallet -= stakeValue;
        liquidityBucket += stakeValue;
    }

    function loanEndUser(address endUserAddress, int loanDesired) public {
        endUser memory user = endUserMap[endUserAddress];
        require(!user.sharkLock);

        int finalLoanCost = loanDesired * 100 / 50;
        require(finalLoanCost <= user.collateral);
        require(liquidityBucket > loanDesired);

        endUserMap[endUserAddress].wallet += loanDesired;
        liquidityBucket -= loanDesired;
    }

    function addCollateralEndUser(address endUserAddress, int collateralAmount) public {
        endUser memory user = endUserMap[endUserAddress];
        require(!user.sharkLock);

        require(collateralAmount <= user.wallet);

        endUserMap[endUserAddress].wallet -= collateralAmount;
        endUserMap[endUserAddress].collateral += collateralAmount;
    }
}
