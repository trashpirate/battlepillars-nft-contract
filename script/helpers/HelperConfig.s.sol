// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";
import {NFTContract} from "./../../src/NFTContract.sol";

contract HelperConfig is Script {
    // deployment arguments

    string public constant NAME = "Battlepillars";
    string public constant SYMBOL = "BATTLEPILLAR";
    string public constant BASE_URI =
        "ipfs://bafybeihvxdrut363rlk65caliu6utzyqo45cm6p5nelbl44hiclo4hhn2i/";
    string public constant CONTRACT_URI =
        "ipfs://bafybeieomuw57yvoi44xkg6zyfzohaxiblr4wv4iafhwnfgprzzc4ot5xa/contractMetadata";
    uint256 public constant MAX_SUPPLY = 235;
    uint96 public constant ROYALTY = 500;

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
                    owner: 0x0d8470Ce3F816f29AA5C0250b64BfB6421332829,
                    feeAddress: 0x0d8470Ce3F816f29AA5C0250b64BfB6421332829,
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
                    owner: 0xA94D468Af30923169e8A146472C03f223dBeB8B0,
                    feeAddress: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                args: NFTContract.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                    feeAddress: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }
}
