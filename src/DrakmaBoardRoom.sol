// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract DrakmaBoardRoom {
    // Self
    address public manager;
    uint256 public stakeBucket;
    uint256 public collateralHoldRef;
    uint256 public supplyRef;
    uint8 public ltv = 50;
    uint8 public sdr = 100; //  Standard daily rate = 10% (100 / 1000 = 0,1)

    struct endUser {
        uint256 wallet;
        uint256 stake;
        uint256 loanValue;
        uint256 lastLoanTimestamp;
        uint256 collateral;
        bool sharkLock; // Blocks any actions until debts are repayed
    }

    mapping(address => endUser) public endUserMap;

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
}
