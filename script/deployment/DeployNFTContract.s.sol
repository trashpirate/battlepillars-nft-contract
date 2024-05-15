// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTContract} from "../../src/NFTContract.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";

contract DeployNFTContract is Script {
    HelperConfig public helperConfig;

    function run() external returns (NFTContract, HelperConfig) {
        helperConfig = new HelperConfig();
        NFTContract.ConstructorArguments memory args = helperConfig.activeNetworkConfig();

        console.log("initial owner: ", args.owner);
        console.log("fee address: ", args.feeAddress);
        console.log("token address: ", args.tokenAddress);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        NFTContract nfts = new NFTContract(args);
        console.log("Deployment gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
