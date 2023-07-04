// SPDX-License-Identifier: MIT

// Fund
// Withdraw

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        //使用 "mostRecentlyDeployed" 地址调用 "FundMe" 合约的 "fund" 函数，并发送 "SEND_VALUE" 数量的以太币。
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        // 获取最近部署的 "FundMe" 合约的地址，并调用 "fundFundMe" 函数。
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        //使用 "mostRecentlyDeployed" 地址调用 "FundMe" 合约的 "fund" 函数，并发送 "SEND_VALUE" 数量的以太币。
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        // 获取最近部署的 "FundMe" 合约的地址，并调用 "fundFundMe" 函数。
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        withdrawFundMe(mostRecentlyDeployed);
    }
}
