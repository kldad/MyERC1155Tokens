// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {MyERC1155Tokens} from "./MyERC1155Tokens.sol";
import {MyERC1155TokensV2} from "./MyERC1155TokensV2.sol";
import {ERC1967Proxy} from "./ERC1967Proxy.sol";
import {Test} from "forge-std/Test.sol";

contract MyERC1155UpgradeTest is Test {
    address trustedForwarder = makeAddr("trustedForwarder");
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");

    function _deployProxy() internal returns (MyERC1155Tokens tokens, ERC1967Proxy proxy) {
        MyERC1155Tokens impl = new MyERC1155Tokens();
        bytes memory initData = abi.encodeCall(MyERC1155Tokens.initialize, (trustedForwarder));
        vm.prank(owner);
        proxy = new ERC1967Proxy(address(impl), initData);
        tokens = MyERC1155Tokens(address(proxy));
    }

    function test_ProxyInitialVersionAndBalances() public {
        (MyERC1155Tokens tokens,) = _deployProxy();

        assertEq(tokens.version(), 1);
        assertTrue(tokens.isOwner(owner));
        assertEq(tokens.balanceOf(owner, 0), 1000);
    }

    function test_UUPSUpgradePreservesStorage() public {
        (MyERC1155Tokens tokens, ERC1967Proxy proxy) = _deployProxy();

        vm.prank(owner);
        tokens.safeTransferFrom(owner, alice, 0, 100, "");

        MyERC1155TokensV2 implV2 = new MyERC1155TokensV2();

        vm.prank(owner);
        tokens.upgradeToAndCall(address(implV2), "");

        assertEq(proxy.implementation(), address(implV2));
        assertEq(tokens.version(), 2);
        assertEq(tokens.balanceOf(owner, 0), 900);
        assertEq(tokens.balanceOf(alice, 0), 100);
        assertEq(tokens.tokenType1TotalSupply(), 1000);
    }

    function test_UUPSUpgradeRevertNotOwner() public {
        (MyERC1155Tokens tokens,) = _deployProxy();
        MyERC1155TokensV2 implV2 = new MyERC1155TokensV2();

        vm.prank(alice);
        vm.expectRevert(bytes("Only contract owner can call this function"));
        tokens.upgradeToAndCall(address(implV2), "");
    }

    function test_ImplementationCannotInitialize() public {
        MyERC1155Tokens impl = new MyERC1155Tokens();
        vm.expectRevert();
        impl.initialize(trustedForwarder);
    }
}
