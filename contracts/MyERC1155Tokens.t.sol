// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {MyERC1155Tokens} from "./MyERC1155Tokens.sol";
import {IERC1155} from "./IERC1155.sol";
import {Test} from "forge-std/Test.sol";

contract MyERC1155TokensTest is Test {
    MyERC1155Tokens public tokens;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(owner);
        tokens = new MyERC1155Tokens();
    }

    function test_InitialBalances() public {
        assertEq( tokens.owner(), owner );

        assertEq( tokens.tokenType1TotalSupply(),  1000 );
        assertEq( tokens.tokenType2TotalSupply(),  5000 );
        assertEq( tokens.tokenType3TotalSupply(), 10000 );

        assertEq( tokens.balanceOf(owner, 0),  1000 );
        assertEq( tokens.balanceOf(owner, 1),  5000 );
        assertEq( tokens.balanceOf(owner, 2), 10000 );

        address[] memory owners = new address[](3);
        owners[0] = owner;
        owners[1] = alice;
        owners[2] = bob;

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory values = new uint256[](9);
        values[0] =  1000;
        values[1] =  5000;
        values[2] = 10000;
        values[3] = 0;
        values[4] = 0;
        values[5] = 0;
        values[6] = 0;
        values[7] = 0;
        values[8] = 0;

        assertEq(tokens.balanceOfBatch(owners, ids), values);
    }

    function test_BalancesAfterMinting() public {
        vm.startPrank(owner);
            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, address(0), owner, 0, 500);        
            tokens.tokenType1Mint(500);

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, address(0), owner, 1, 2500);        
            tokens.tokenType2Mint(2500);

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, address(0), owner, 2, 5000);        
            tokens.tokenType3Mint(5000);
        vm.stopPrank();

        assertEq( tokens.tokenType1TotalSupply(),  1500 );
        assertEq( tokens.tokenType2TotalSupply(),  7500 );
        assertEq( tokens.tokenType3TotalSupply(), 15000 );

        assertEq( tokens.balanceOf(owner, 0),  1500 );
        assertEq( tokens.balanceOf(owner, 1),  7500 );
        assertEq( tokens.balanceOf(owner, 2), 15000 );

        address[] memory owners = new address[](1);
        owners[0] = owner;

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory values = new uint256[](3);
        values[0] =  1500;
        values[1] =  7500;
        values[2] = 15000;

        assertEq(tokens.balanceOfBatch(owners, ids), values);
    }    

    function test_BalancesAfterSafeTransferFromThenOperatorEqualToOwner() public {
        vm.startPrank(owner);
            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, owner, alice, 0, 100);        
            tokens.safeTransferFrom(owner, alice, 0, 100, "");

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, owner, bob, 0, 200);        
            tokens.safeTransferFrom(owner, bob, 0, 200, "");

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, owner, alice, 1, 300);        
            tokens.safeTransferFrom(owner, alice, 1, 300, "");

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, owner, bob, 1, 400);        
            tokens.safeTransferFrom(owner, bob, 1, 400, "");

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, owner, alice, 2, 500);        
            tokens.safeTransferFrom(owner, alice, 2, 500, "");

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(owner, owner, bob, 2, 600);        
            tokens.safeTransferFrom(owner, bob, 2, 600, "");
        vm.stopPrank();

        assertEq( tokens.balanceOf(owner, 0),  700 );
        assertEq( tokens.balanceOf(owner, 1), 4300 );
        assertEq( tokens.balanceOf(owner, 2), 8900 );

        assertEq( tokens.balanceOf(alice, 0),  100 );
        assertEq( tokens.balanceOf(alice, 1),  300 );
        assertEq( tokens.balanceOf(alice, 2),  500 );

        assertEq( tokens.balanceOf(bob,   0),  200 );
        assertEq( tokens.balanceOf(bob,   1),  400 );
        assertEq( tokens.balanceOf(bob,   2),  600 );

        address[] memory owners = new address[](3);
        owners[0] = owner;
        owners[1] = alice;
        owners[2] = bob;

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory values = new uint256[](9);
        values[0] =  700;
        values[1] = 4300;
        values[2] = 8900;
        values[3] =  100;
        values[4] =  300;
        values[5] =  500;
        values[6] =  200;
        values[7] =  400;
        values[8] =  600;

        assertEq(tokens.balanceOfBatch(owners, ids), values);
    }    

    function test_BalancesAfterSafeTransferFromThenOperatorNotEqualToOwner() public {
        vm.startPrank(owner);
            vm.expectEmit(true, true, false, true, address(tokens));
            emit IERC1155.ApprovalForAll(owner, alice, true);        
            tokens.setApprovalForAll(alice, true);
        vm.stopPrank();

        assertEq( tokens.isApprovedForAll(owner, alice),  true );

        vm.startPrank(alice);
            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(alice, owner, alice, 1, 5000);        
            tokens.safeTransferFrom(owner, alice, 1, 5000, "");

            vm.expectEmit(true, true, true, true, address(tokens));
            emit IERC1155.TransferSingle(alice, owner, bob, 2, 10000);        
            tokens.safeTransferFrom(owner, bob, 2, 10000, "");
        vm.stopPrank();

        assertEq( tokens.balanceOf(owner, 0),  1000 );
        assertEq( tokens.balanceOf(owner, 1),     0 );
        assertEq( tokens.balanceOf(owner, 2),     0 );

        assertEq( tokens.balanceOf(alice, 0),     0 );
        assertEq( tokens.balanceOf(alice, 1),  5000 );
        assertEq( tokens.balanceOf(alice, 2),     0 );

        assertEq( tokens.balanceOf(bob,   0),     0 );
        assertEq( tokens.balanceOf(bob,   1),     0 );
        assertEq( tokens.balanceOf(bob,   2), 10000 );

        address[] memory owners = new address[](3);
        owners[0] = owner;
        owners[1] = alice;
        owners[2] = bob;

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory values = new uint256[](9);
        values[0] =  1000;
        values[1] =     0;
        values[2] =     0;
        values[3] =     0;
        values[4] =  5000;
        values[5] =     0;
        values[6] =     0;
        values[7] =     0;
        values[8] = 10000;

        assertEq(tokens.balanceOfBatch(owners, ids), values);
    }    
}
