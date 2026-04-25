// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FractalSequencerV2.sol";

contract FractalSequencerV3Test is Test {
    FractalSequencerV2 public sequencer;
    address public user1 = address(0x111);
    address public hacker = address(0x222);

    function setUp() public {
        vm.roll(100);
        sequencer = new FractalSequencerV2();
        vm.deal(user1, 10 ether);
        vm.deal(hacker, 10 ether);
    }

    function test_RevertIf_DepositTooLow() public {
        vm.prank(hacker);
        vm.expectRevert("Must deposit exactly 0.1 ETH"); 
        sequencer.commitTransaction{value: 0.05 ether}(keccak256(abi.encodePacked(uint256(1), hacker)));
    }

    function test_AutomaticTransitionAfterDeadline() public {
        vm.prank(user1);
        sequencer.commitTransaction{value: 0.1 ether}(keccak256(abi.encodePacked(uint256(123), user1)));
        
        uint256 targetDeadline = sequencer.deadline();

        // 데드라인 당일(105)까지는 실패해야 함
        vm.roll(targetDeadline);
        vm.expectRevert("Not ready to reveal");
        sequencer.startRevealPhase();

        // 데드라인 다음날(106) 성공
        vm.roll(targetDeadline + 1);
        sequencer.startRevealPhase();
        assertEq(uint(sequencer.state()), 1);
    }

    function test_SlashingAndReward() public {
        vm.prank(user1);
        sequencer.commitTransaction{value: 0.1 ether}(keccak256(abi.encodePacked(uint256(123), user1)));
        vm.prank(hacker);
        sequencer.commitTransaction{value: 0.1 ether}(keccak256(abi.encodePacked(uint256(999), hacker)));

        vm.roll(sequencer.deadline() + 1);
        sequencer.startRevealPhase();

        vm.prank(user1);
        sequencer.revealTransaction(123);

        vm.roll(sequencer.deadline() + 1);

        uint256 balanceBefore = user1.balance;
        sequencer.closeRound();
        assertEq(user1.balance, balanceBefore + 0.1 ether);
    }
}
