// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFTContract} from "../../src/NFTContract.sol";
import {ERC20Token} from "./../../src/ERC20Token.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {DeployNFTContract} from "./../../script/deployment/DeployNFTContract.s.sol";
import {MintNft, BatchMint, TransferNft, ApproveNft, BurnNft} from "./../../script/interactions/Interactions.s.sol";

contract TestInteractions is Test {
    // configuration
    DeployNFTContract deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    ERC20Token token;
    NFTContract nftContract;

    // users
    address contractOwner;

    // helpers
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 500_000_000 ether;

    // modifiers
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

    modifier funded(address account) {
        // fund user with eth
        deal(account, 1000 ether);

        // fund user tokens
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();

        // approve tokens
        vm.prank(account);
        token.approve(address(nftContract), STARTING_BALANCE);
        _;
    }

    modifier unpaused() {
        vm.startPrank(nftContract.owner());
        nftContract.pause(false);
        vm.stopPrank();
        _;
    }

    // setup
    function setUp() external {
        deployment = new DeployNFTContract();
        (nftContract, helperConfig) = deployment.run();
        contractOwner = nftContract.owner();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();
        token = ERC20Token(nftContract.getPaymentToken());
    }

    /**
     * MINT
     */
    function test__SingleMint() public funded(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(nftContract));
        assertEq(nftContract.balanceOf(msg.sender), 1);
    }

    /**
     * BATCH MINT
     */
    function test__BatchMint() public funded(msg.sender) unpaused {
        BatchMint batchMint = new BatchMint();
        batchMint.batchMint(address(nftContract));
        assertEq(
            nftContract.balanceOf(msg.sender),
            nftContract.getBatchLimit()
        );
    }

    /**
     * TRANSFER
     */
    function test__TransferNft() public funded(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(nftContract));
        assert(nftContract.balanceOf(msg.sender) == 1);

        TransferNft transferNft = new TransferNft();
        transferNft.transferNft(address(nftContract));
        assertEq(nftContract.balanceOf(msg.sender), 0);
    }

    /**
     * APPROVE
     */
    function test__ApproveNft() public funded(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(nftContract));
        assertEq(nftContract.balanceOf(msg.sender), 1);

        ApproveNft approveNft = new ApproveNft();
        approveNft.approveNft(address(nftContract));

        assertEq(nftContract.getApproved(1), approveNft.SENDER());
    }

    /**
     * BURN
     */
    function test__BurnNft() public funded(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(nftContract));
        assertEq(nftContract.balanceOf(msg.sender), 1);

        BurnNft burnNft = new BurnNft();
        burnNft.burnNft(address(nftContract));

        assertEq(nftContract.balanceOf(msg.sender), 0);
    }
}
