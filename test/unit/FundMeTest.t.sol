//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); //Fake New Address
    uint256 constant SEND_VALUE = 0.1 ether; // 100_000_000_000_000_000
    uint256 constant STARTING_BALANCE = 10 ether;

    // uint256 constant GAS_PRICE = 1; // 1 wei

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // foundry cheatcode to send money to fake new address
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testSenderIsMsgOwner() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsCorrect() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // Hey, the next line should revert!
        // assert(This tx fails/reverts)
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent be USER (Fake Address)
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFundertoArrayOfFunders() public {
        vm.prank(USER); // The next TX will be sent be USER (Fake Address)
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); // The next TX will be sent be USER (Fake Address)
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER); // The next TX will be sent be USER (Fake Address)
        // fundMe.fund{value: SEND_VALUE}();
        // Used funded modifier instead

        vm.prank(USER); // vm will go over the next vm command
        vm.expectRevert(); // Hey, the next line should revert!
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        /**
         * Arrange, Act, Assert
         */

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // // NO GAS SPENT ON LOCAL ANVIL CHAIN, have to use  cheatcodes to set gas price in order to test gas usage.
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // vm will go over the next vm command
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // Here tx.gasprice is the current gas price, i.e. GAS_PRICE
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log("Gas used: ", gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        /**
         * Arrange, Act, Assert
         */
        //Arrange
        uint160 numberOfFunders = 10; // Using uint160 because uint160 has same places as in an address
        uint160 startingNumberOfFunders = 1;

        for (uint160 i = startingNumberOfFunders; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // hoax does both things at the same time
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        //Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // vm.startPrank and vm.stopPrank works same as vm.startBroadcast and vm.stopBroadcast
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        /**
         * Arrange, Act, Assert
         */
        //Arrange
        uint160 numberOfFunders = 10; // Using uint160 because uint160 has same places as in an address
        uint160 startingNumberOfFunders = 1;

        for (uint160 i = startingNumberOfFunders; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // hoax does both things at the same time
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        //Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // vm.startPrank and vm.stopPrank works same as vm.startBroadcast and vm.stopBroadcast
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}
