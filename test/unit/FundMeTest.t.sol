// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; //2.1

contract FundMeTest is Test {
    FundMe fundMe;

    //makeAdd用于创建一个地址对象
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //
    uint256 STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    //部署合约: us -> FundMeTest -> FundMe (合约的owner是FundMeTest而不是us,所以写address(this)，而不是写msg.sender)
    //每次测试都是先setup，然后进行一个测试，然后再setup,再进行下一个测试
    function setUp() external {
        //fundMe = new FundMe();
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //2.1
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        //deal模拟转账: 给假user假的10 ether
        vm.deal(USER, STARTING_BALANCE);
    }

    //测试
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        //assertEq(fundMe.i_owner(), address(this));
        //assertEq(fundMe.i_owner(), msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        //cheatcode: expect revert 表示"hey the next line should revert" 验证出现错误时是否会报错，没有报错就是test tail
        // assert(THis ts fails.reverts);
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        //prank模拟任何账户的任何调用：将当前msg.sender（而不是实际的调用者地址）指定为下一次调用的地址（这样就知道了是谁调用的）；
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        //只有一个用户投资
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    //避免每个测试都要写这些代码
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange  Act Assert
        // Arrage
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        //计算提款花费多少gas: 也就是比较提款前有多少gas、提款后有多少gas
        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        //console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        //在Solidity 0.8版本及更高版本中，不能再直接将address类型显式转换为uint256类型。需要使用uint160进行中间转换，例如：uint256 i = uint256(uint160(msg.sender));。这样可以将address类型转换为uint160类型，再将uint160类型转换为uint256类型。
        uint160 numberOfFunders = 10;
        //从1开始因为零地址（zero address）会导致回滚并阻止你对其进行操作：在以太坊中，零地址是特殊的地址，表示一个无效的地址。当你在合约中进行转账或与其他合约进行交互时，如果目标地址是零地址，这些操作通常会被视为无效并导致回滚。
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        //在Solidity 0.8版本及更高版本中，不能再直接将address类型显式转换为uint256类型。需要使用uint160进行中间转换，例如：uint256 i = uint256(uint160(msg.sender));。这样可以将address类型转换为uint160类型，再将uint160类型转换为uint256类型。
        uint160 numberOfFunders = 10;
        //从1开始因为零地址（zero address）会导致回滚并阻止你对其进行操作：在以太坊中，零地址是特殊的地址，表示一个无效的地址。当你在合约中进行转账或与其他合约进行交互时，如果目标地址是零地址，这些操作通常会被视为无效并导致回滚。
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}

//四种测试
//unit测试部分代码，比如测试一个函数，然后再测试另一个函数；
//integration 测试一个函数时，其实也在测试相关的几个合约是否能正常运行
//staging部署在测试网或主网后的测试
