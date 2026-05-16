// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {AccessControl} from "./AccessControl.sol";
import {Test} from "forge-std/Test.sol";

/// @dev Изолированная оболочка: фиксирует вызов `blackListedAction` и даёт точку входа для `notBlackListed`.
contract AccessControlHarness is AccessControl {
    address public lastBlacklistedUser;
    uint256 public blacklistedActionCount;

    function blackListedAction(address user) public override {
        lastBlacklistedUser = user;
        unchecked {
            ++blacklistedActionCount;
        }
    }

    function gated() external view notBlackListed returns (uint256) {
        return 1;
    }
}

contract AccessControlTest is Test {
    AccessControlHarness internal ac;

    address internal owner;
    address internal alice;
    address internal bob;
    address internal carol;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");

        vm.prank(owner);
        ac = new AccessControlHarness();
    }

    /* ---------- начальное состояние ---------- */

    function test_InitialOwnerAndRoles() public view {
        assertTrue(ac.isOwner(owner));
        assertTrue(ac.isAdmin(owner));
        assertTrue(ac.isModerator(owner));
        assertFalse(ac.isBlackListed(owner));

        assertFalse(ac.isOwner(alice));
        assertFalse(ac.isAdmin(alice));
        assertFalse(ac.isModerator(alice));
    }

    /* ---------- addAdmin / removeAdmin ---------- */

    function test_AddAdmin_Success() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(ac));
        emit AccessControl.AccessControlAdminRoleAssigned(owner, alice);
        ac.addAdmin(alice);

        assertTrue(ac.isAdmin(alice));
        assertTrue(ac.isModerator(alice));
    }

    function test_AddAdmin_RevertNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Only contract owner can call this function"));
        ac.addAdmin(bob);
    }

    function test_AddAdmin_RevertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, address(0)));
        ac.addAdmin(address(0));
    }

    function test_AddAdmin_RevertOwnerCannotAddSelfAsAdminEntry() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, owner));
        ac.addAdmin(owner);
    }

    function test_AddAdmin_RevertAlreadyAdmin() public {
        vm.startPrank(owner);
        ac.addAdmin(alice);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, alice));
        ac.addAdmin(alice);
        vm.stopPrank();
    }

    function test_AddAdmin_RevertUserBlackListed() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(alice);
        ac.addToBlackList(bob);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControl.AccessControlRoleAssignmentUnavailableForBlackListed.selector, owner, bob)
        );
        ac.addAdmin(bob);
    }

    function test_RemoveAdmin_Success() public {
        vm.startPrank(owner);
        ac.addAdmin(alice);
        vm.expectEmit(true, true, true, true, address(ac));
        emit AccessControl.AccessControlAdminRoleRemoved(owner, alice);
        ac.removeAdmin(alice);
        vm.stopPrank();

        assertFalse(ac.isAdmin(alice));
    }

    function test_RemoveAdmin_RevertNotOwner() public {
        vm.prank(owner);
        ac.addAdmin(alice);

        vm.prank(alice);
        vm.expectRevert(bytes("Only contract owner can call this function"));
        ac.removeAdmin(alice);
    }

    function test_RemoveAdmin_RevertNotAdmin() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, alice));
        ac.removeAdmin(alice);
    }

    /* ---------- addModerator / removeModerator ---------- */

    function test_AddModerator_ByOwner_Success() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(ac));
        emit AccessControl.AccessControlModeratorRoleAssigned(owner, alice);
        ac.addModerator(alice);

        assertTrue(ac.isModerator(alice));
        assertFalse(ac.isAdmin(alice));
    }

    function test_AddModerator_ByAdmin_Success() public {
        vm.prank(owner);
        ac.addAdmin(alice);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(ac));
        emit AccessControl.AccessControlModeratorRoleAssigned(alice, bob);
        ac.addModerator(bob);

        assertTrue(ac.isModerator(bob));
        assertFalse(ac.isAdmin(bob));
    }

    function test_AddModerator_RevertStranger() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Only admin can call this function"));
        ac.addModerator(bob);
    }

    function test_AddModerator_RevertOwnerCannotTargetSelf() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, owner));
        ac.addModerator(owner);
    }

    function test_AddModerator_RevertCannotPromoteOwnerAddress() public {
        vm.prank(owner);
        ac.addAdmin(alice);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControl.AccessControlRoleAssignmentUnavailableForContractOwner.selector, alice, owner)
        );
        ac.addModerator(owner);
    }

    function test_AddModerator_RevertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, address(0)));
        ac.addModerator(address(0));
    }

    function test_AddModerator_RevertAdminCannotAddSelf() public {
        vm.prank(owner);
        ac.addAdmin(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, alice, alice));
        ac.addModerator(alice);
    }

    function test_AddModerator_RevertAlreadyModerator() public {
        vm.startPrank(owner);
        ac.addModerator(alice);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, alice));
        ac.addModerator(alice);
        vm.stopPrank();
    }

    function test_AddModerator_RevertUserBlackListed() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(alice);
        ac.addToBlackList(bob);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControl.AccessControlRoleAssignmentUnavailableForBlackListed.selector, owner, bob)
        );
        ac.addModerator(bob);
    }

    function test_RemoveModerator_ByAdmin_Success() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(ac));
        emit AccessControl.AccessControlModeratorRoleRemoved(owner, alice);
        ac.removeModerator(alice);

        assertFalse(ac.isModerator(alice));
    }

    function test_RemoveModerator_RevertPureModeratorCannotCall() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(alice);
        vm.expectRevert(bytes("Only admin can call this function"));
        ac.removeModerator(alice);
    }

    function test_RemoveModerator_RevertNotModerator() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, alice));
        ac.removeModerator(alice);
    }

    /* ---------- blacklist ---------- */

    function test_AddToBlackList_ByOwner_CallsHookAndSetsFlag() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(ac));
        emit AccessControl.AccessControlUserBlackListed(owner, alice);
        ac.addToBlackList(alice);

        assertTrue(ac.isBlackListed(alice));
        assertEq(ac.lastBlacklistedUser(), alice);
        assertEq(ac.blacklistedActionCount(), 1);
        assertFalse(ac.isAdmin(alice));
        assertFalse(ac.isModerator(alice));
    }

    function test_AddToBlackList_ByModerator_Success() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(alice);
        ac.addToBlackList(bob);

        assertTrue(ac.isBlackListed(bob));
        assertEq(ac.lastBlacklistedUser(), bob);
    }

    function test_AddToBlackList_RevertStranger() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Only moderator can call this function"));
        ac.addToBlackList(bob);
    }

    function test_AddToBlackList_RevertCannotBlacklistOwner() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, owner));
        ac.addToBlackList(owner);
    }

    function test_AddToBlackList_RevertModeratorCannotBlacklistOwnerAddress() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControl.AccessControlRoleAssignmentUnavailableForContractOwner.selector, alice, owner)
        );
        ac.addToBlackList(owner);
    }

    function test_AddToBlackList_RevertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, address(0)));
        ac.addToBlackList(address(0));
    }

    function test_AddToBlackList_RevertCannotBlacklistSelf() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, alice, alice));
        ac.addToBlackList(alice);
    }

    function test_AddToBlackList_RevertAlreadyBlackListed() public {
        vm.startPrank(owner);
        ac.addToBlackList(alice);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlInvalidUser.selector, owner, alice));
        ac.addToBlackList(alice);
        vm.stopPrank();
    }

    function test_AddToBlackList_ClearsAdminAndModeratorRoles() public {
        vm.prank(owner);
        ac.addAdmin(alice);

        vm.prank(owner);
        ac.addToBlackList(alice);

        assertTrue(ac.isBlackListed(alice));
        assertFalse(ac.isAdmin(alice));
    }

    function test_AddToBlackList_ClearsModeratorRole() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(owner);
        ac.addToBlackList(alice);

        assertTrue(ac.isBlackListed(alice));
        assertFalse(ac.isModerator(alice));
    }

    /* ---------- notBlackListed (через harness.gated) ---------- */

    function test_NotBlackListed_AllowsGated() public {
        vm.prank(alice);
        assertEq(ac.gated(), 1);
    }

    function test_NotBlackListed_RevertWhenBlackListed() public {
        vm.prank(owner);
        ac.addToBlackList(alice);

        vm.prank(alice);
        vm.expectRevert(bytes("Access denied"));
        ac.gated();
    }

    /* ---------- сценарий: админ после модератора ---------- */

    function test_Scenario_PromoteModeratorThenBlacklist() public {
        vm.prank(owner);
        ac.addModerator(alice);

        vm.prank(alice);
        ac.addToBlackList(bob);

        vm.prank(owner);
        ac.addAdmin(carol);

        assertTrue(ac.isAdmin(carol));
        assertTrue(ac.isBlackListed(bob));
    }
}
