// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {DeployNFTContract} from "./../../script/deployment/DeployNFTContract.s.sol";
import {NFTContract} from "./../../src/NFTContract.sol";
import {ERC20Token} from "./../../src/ERC20Token.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestHelper {
    mapping(string => bool) public tokenUris;

    function setTokenUri(string memory tokenUri) public {
        tokenUris[tokenUri] = true;
    }

    function isTokenUriSet(string memory tokenUri) public view returns (bool) {
        return tokenUris[tokenUri];
    }
}

contract TestUserFunctions is Test {
    // configuration
    DeployNFTContract deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    ERC20Token token;
    NFTContract nftContract;

    // helpers
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 500_000_000 ether;

    // events
    event MetadataUpdated(uint256 indexed tokenId);

    // modifiers
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
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

    modifier noBatchLimit() {
        vm.startPrank(nftContract.owner());
        nftContract.setBatchLimit(100);
        vm.stopPrank();
        _;
    }

    function setUp() external virtual {
        deployment = new DeployNFTContract();
        (nftContract, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();
        token = ERC20Token(nftContract.getPaymentToken());
    }

    function fund(address account) public {
        // fund user with eth
        deal(account, 10000 ether);

        // fund user tokens
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();

        // approve tokens
        vm.prank(account);
        token.approve(address(nftContract), STARTING_BALANCE);
    }

    /**
     * MINT
     */
    function test__Mint(
        uint256 quantity,
        address account
    ) public unpaused noBatchLimit skipFork {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());
        vm.assume(account != address(0));

        fund(account);

        uint256 feeEthBalance = nftContract.getFeeAddress().balance;
        uint256 feeTokenBalance = token.balanceOf(nftContract.getFeeAddress());
        uint256 ethBalance = account.balance;
        uint256 tokenBalance = token.balanceOf(account);
        uint256 tokenFee = quantity * nftContract.getTokenFee();
        uint256 ethFee = quantity * nftContract.getEthFee();

        vm.prank(account);
        nftContract.mint{value: ethFee}(quantity);

        assertEq(nftContract.balanceOf(account), quantity);
        assertEq(account.balance, ethBalance - ethFee);
        assertEq(token.balanceOf(account), tokenBalance - tokenFee);
        assertEq(nftContract.getFeeAddress().balance, feeEthBalance + ethFee);
        assertEq(
            token.balanceOf(nftContract.getFeeAddress()),
            feeTokenBalance + tokenFee
        );
    }

    function test__EmitEvent__Mint() public funded(USER) unpaused noBatchLimit {
        uint256 tokenFee = nftContract.getTokenFee();
        uint256 ethFee = nftContract.getEthFee();

        vm.expectEmit(true, true, true, true);
        emit MetadataUpdated(1);

        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
    }

    function test__ChargesNoTokenFeeIfTokenFeeIsZero()
        public
        unpaused
        noBatchLimit
        skipFork
    {
        uint256 quantity = 1;
        deal(USER, 1 ether);
        uint256 ethBalance = USER.balance;
        uint256 tokenBalance = token.balanceOf(USER);
        uint256 ethFee = quantity * nftContract.getEthFee();

        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setTokenFee(0);

        vm.prank(USER);
        nftContract.mint{value: ethFee}(quantity);

        // correct nft balance
        assertEq(nftContract.balanceOf(USER), quantity);

        // correct nft ownership
        assertEq(nftContract.ownerOf(1), USER);

        // correct eth fee charged
        assertEq(USER.balance, ethBalance - ethFee);

        // correct token fee charged
        assertEq(token.balanceOf(USER), tokenBalance);

        // fee sent to correct address
        assertEq(nftContract.getFeeAddress().balance, ethFee);
    }

    function test__ChargesNoFeeIfZeroEthFee()
        public
        unpaused
        noBatchLimit
        funded(USER)
        skipFork
    {
        uint256 ethBalance = USER.balance;
        uint256 tokenBalance = token.balanceOf(USER);
        uint256 tokenFee = nftContract.getTokenFee();

        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setEthFee(0);

        vm.prank(USER);
        nftContract.mint(1);

        // correct nft balance
        assertEq(nftContract.balanceOf(USER), 1);

        // correct nft ownership
        assertEq(nftContract.ownerOf(1), USER);

        // correct eth fee charged
        assertEq(USER.balance, ethBalance);

        // correct token fee charged
        assertEq(token.balanceOf(USER), tokenBalance - tokenFee);
    }

    function test__RevertWhen__Paused() public funded(USER) {
        uint256 ethFee = nftContract.getEthFee();

        vm.expectRevert(NFTContract.NFTContract_ContractIsPaused.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
    }

    function test__RevertWhen__InsufficientEthFee(
        uint256 quantity
    ) public funded(USER) unpaused skipFork {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());

        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 insufficientFee = ethFee - 0.01 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                NFTContract.NFTContract_InsufficientEthFee.selector,
                insufficientFee,
                ethFee
            )
        );
        vm.prank(USER);
        nftContract.mint{value: insufficientFee}(quantity);
    }

    function test__RevertWhen__InsufficientTokenFee(
        uint256 quantity
    ) public unpaused skipFork {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());

        deal(USER, 1000 ether);
        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 tokenFee = nftContract.getTokenFee() * quantity;

        vm.expectRevert(
            abi.encodeWithSelector(
                NFTContract.NFTContract_InsufficientTokenBalance.selector,
                0,
                tokenFee
            )
        );
        vm.prank(USER);
        nftContract.mint{value: ethFee}(quantity);
    }

    function test__RevertWhen__InsufficientMintQuantity()
        public
        funded(USER)
        unpaused
    {
        uint256 ethFee = nftContract.getEthFee();

        vm.expectRevert(
            NFTContract.NFTContract_InsufficientMintQuantity.selector
        );
        vm.prank(USER);
        nftContract.mint{value: ethFee}(0);
    }

    function test__RevertWhen__MintExceedsBatchLimit()
        public
        funded(USER)
        unpaused
    {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setBatchLimit(5);

        uint256 quantity = 6;
        uint256 ethFee = nftContract.getEthFee() * quantity;

        vm.expectRevert(NFTContract.NFTContract_ExceedsBatchLimit.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(quantity);
    }

    function test__RevertWhen__MaxSupplyExceeded()
        public
        funded(USER)
        unpaused
    {
        uint256 fee = nftContract.getEthFee();
        uint256 maxSupply = nftContract.getMaxSupply();

        for (uint256 index = 0; index < maxSupply; index++) {
            vm.prank(USER);
            nftContract.mint{value: fee}(1);
        }

        vm.expectRevert(NFTContract.NFTContract_ExceedsMaxSupply.selector);
        vm.prank(USER);
        nftContract.mint{value: fee}(1);
    }

    function test__RevertsWhen__TokenTransferFails()
        public
        funded(USER)
        unpaused
    {
        uint256 ethFee = nftContract.getEthFee();
        uint256 tokenFee = nftContract.getTokenFee();

        address feeAccount = nftContract.getFeeAddress();
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(
                token.transferFrom.selector,
                USER,
                feeAccount,
                tokenFee
            ),
            abi.encode(false)
        );

        vm.expectRevert(NFTContract.NFTContract_TokenTransferFailed.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
    }

    /**
     * TRANSFER
     */
    function test__Transfer(
        address account,
        address receiver
    ) public unpaused noBatchLimit skipFork {
        uint256 quantity = 1; //bound(numOfNfts, 1, 100);
        vm.assume(account != address(0));
        vm.assume(receiver != address(0));

        fund(account);

        uint256 ethFee = quantity * nftContract.getEthFee();

        vm.prank(account);
        nftContract.mint{value: ethFee}(quantity);

        assertEq(nftContract.balanceOf(account), quantity);
        assertEq(nftContract.ownerOf(1), account);

        vm.prank(account);
        nftContract.transferFrom(account, receiver, 1);

        assertEq(nftContract.ownerOf(1), receiver);
        assertEq(nftContract.balanceOf(receiver), quantity);
    }

    /**
     * TOKEN URI
     */
    function test__RetrieveTokenUri() public funded(USER) unpaused {
        uint256 ethFee = nftContract.getEthFee();

        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
        assertEq(nftContract.balanceOf(USER), 1);
        assertEq(
            nftContract.tokenURI(1),
            string.concat(networkConfig.args.baseURI, "1")
        );
    }

    /// forge-config: default.fuzz.runs = 3
    function test__UniqueTokenURI(
        uint256 roll
    ) public funded(USER) unpaused noBatchLimit skipFork {
        roll = bound(roll, 0, 100000000000);
        TestHelper testHelper = new TestHelper();

        uint256 maxSupply = nftContract.getMaxSupply();

        vm.startPrank(USER);
        for (uint256 index = 0; index < maxSupply; index++) {
            vm.prevrandao(bytes32(uint256(index + roll)));
            uint256 ethFee = nftContract.getEthFee();

            nftContract.mint{value: ethFee}(1);
            assertEq(
                testHelper.isTokenUriSet(nftContract.tokenURI(index + 1)),
                false
            );
            console.log(nftContract.tokenURI(index + 1));
            testHelper.setTokenUri(nftContract.tokenURI(index + 1));
        }
        vm.stopPrank();
    }
}
