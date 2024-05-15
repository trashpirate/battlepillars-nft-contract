// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721A} from "@erc721a/contracts/IERC721A.sol";
import {DeployNFTContract} from "./../../script/deployment/DeployNFTContract.s.sol";
import {NFTContract} from "./../../src/NFTContract.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestDeployment is Test {
    // configuration
    DeployNFTContract deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    NFTContract nftContract;

    function setUp() external virtual {
        deployment = new DeployNFTContract();
        (nftContract, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();
    }

    /**
     * INITIALIZATION
     */
    function test__Initialization() public {
        assertEq(nftContract.getMaxSupply(), networkConfig.args.maxSupply);

        assertEq(nftContract.getFeeAddress(), networkConfig.args.feeAddress);
        assertEq(nftContract.getBaseURI(), networkConfig.args.baseURI);
        assertEq(nftContract.contractURI(), networkConfig.args.contractURI);

        assertEq(nftContract.getBatchLimit(), 50);
        assertEq(nftContract.getTokenFee(), networkConfig.args.tokenFee);
        assertEq(nftContract.getEthFee(), networkConfig.args.ethFee);
        assertEq(nftContract.isPaused(), true);

        assertEq(nftContract.supportsInterface(0x80ac58cd), true); // ERC721
        assertEq(nftContract.supportsInterface(0x2a55205a), true); // ERC2981

        uint256 salePrice = 100;
        (address feeAddress, uint256 royaltyAmount) = nftContract.royaltyInfo(
            0,
            salePrice
        );
        assertEq(feeAddress, networkConfig.args.feeAddress);
        assertEq(
            royaltyAmount,
            (networkConfig.args.royaltyNumerator * 100) / 10000
        );

        vm.expectRevert(IERC721A.URIQueryForNonexistentToken.selector);
        nftContract.tokenURI(1);
    }

    /**
     * DEPLOYMENT
     */
    function test__Deployment() public {
        NFTContract.ConstructorArguments memory args = networkConfig.args;

        args.baseURI = "";

        vm.expectRevert(NFTContract.NFTContract_NoBaseURI.selector);
        new NFTContract(args);
    }
}
