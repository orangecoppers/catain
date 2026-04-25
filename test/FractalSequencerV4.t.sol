// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FractalSequencerV4.sol";

contract FractalSequencerV4Test is Test {
    FractalSequencerV4 public sequencer;

    address public user1 = address(0x111);
    address public user2 = address(0x222);

    uint256 public amount1 = 0.2 ether;
    uint256 public amount2 = 0.1 ether;

    bytes32 public root;
    bytes32[] public proof1;

    function setUp() public {
        sequencer = new FractalSequencerV4();

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        // Create leaves
        bytes32 leaf1 = keccak256(abi.encodePacked(user1, amount1));
        bytes32 leaf2 = keccak256(abi.encodePacked(user2, amount2));

        // Build sorted Merkle root
        if (leaf1 < leaf2) {
            root = keccak256(abi.encodePacked(leaf1, leaf2));
            proof1.push(leaf2);
        } else {
            root = keccak256(abi.encodePacked(leaf2, leaf1));
            proof1.push(leaf1);
        }

        // Fund contract
        vm.deal(address(sequencer), 1 ether);

        // Finalize round
        sequencer.finalizeRound(root);
    }

    function test_Claim_Success() public {
        uint256 balanceBefore = user1.balance;

        vm.prank(user1);
        sequencer.claim(0, proof1, amount1);

        assertEq(user1.balance, balanceBefore + amount1);
    }

    function test_Revert_DoubleClaim() public {
        vm.startPrank(user1);

        sequencer.claim(0, proof1, amount1);

        vm.expectRevert("Already claimed");
        sequencer.claim(0, proof1, amount1);

        vm.stopPrank();
    }

    function test_Revert_InvalidProof() public {
        bytes32[] memory wrongProof = new bytes32[](1);
        wrongProof[0] = keccak256("fake");

        vm.prank(user1);

        vm.expectRevert("Invalid proof");
        sequencer.claim(0, wrongProof, amount1);
    }

    function test_Revert_InvalidRound() public {
        vm.prank(user1);

        vm.expectRevert("Invalid round");
        sequencer.claim(999, proof1, amount1);
    }
}
