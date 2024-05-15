// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";
import {NFTContract} from "./../../src/NFTContract.sol";

contract HelperConfig is Script {
    // deployment arguments
    address public constant TOKENOWNER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    string public constant NAME = "NFT Collection";
    string public constant SYMBOL = "MYNFT";
    string public constant BASE_URI =
        "ipfs://bafybeihgsbcbmy3k3iowwhwv2kabdnvwsp2tee5bfm5yzwjvw7roc52spm/";
    string public constant CONTRACT_URI =
        "ipfs://bafybeihgsbcbmy3k3iowwhwv2kabdnvwsp2tee5bfm5yzwjvw7roc52spm/";
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public constant TOKEN_FEE = 500 ether;
    uint256 public constant ETH_FEE = 0.05 ether;
    uint96 public constant ROYALTY = 100;

    // chain configurations
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        NFTContract.ConstructorArguments args;
    }

    constructor() {
        if (
            block.chainid == 1 || block.chainid == 56 || block.chainid == 8453
        ) {
            activeNetworkConfig = getMainnetConfig();
        } else if (
            block.chainid == 11155111 ||
            block.chainid == 97 ||
            block.chainid == 84532 ||
            block.chainid == 84531 ||
            block.chainid == 80001
        ) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getActiveNetworkConfigStruct()
        public
        view
        returns (NetworkConfig memory)
    {
        return activeNetworkConfig;
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                args: NFTContract.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    owner: 0x4671a210C4CF44C43dC5E44DAf68e64D46cdc703,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    feeAddress: 0x0cf66382d52C2D6c1D095c536c16c203117E2B2f,
                    tokenAddress: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }

    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                args: NFTContract.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    owner: 0x11F392Ba82C7d63bFdb313Ca63372F6De21aB448,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    feeAddress: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF,
                    tokenAddress: 0xf061681021Dd0d840ed49bA88B57aE1430c8a962,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // Deploy mock contract
        vm.startBroadcast();
        ERC20Token token = new ERC20Token(TOKENOWNER);
        vm.stopBroadcast();

        return
            NetworkConfig({
                args: NFTContract.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    feeAddress: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                    tokenAddress: address(token),
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }
}
