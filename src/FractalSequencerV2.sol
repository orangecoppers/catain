// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FractalSequencerV2 {
    enum RoundState { Commit, Reveal, Closed }
    RoundState public state;
    uint256 public currentRound;
    uint256 public constant DEPOSIT_AMOUNT = 0.1 ether;
    uint256 public constant PHASE_DURATION = 5; 
    
    // 🔥 public을 추가하여 외부(테스트 코드)에서 읽을 수 있게 함
    uint256 public deadline; 

    struct Participant {
        bytes32 commitment;
        bool hasRevealed;
    }

    mapping(address => Participant) public participants;
    address[] public participantAddresses;
    address[] public honestParticipants;
    uint256 public finalSeed;

    event CommitPhaseClosed(uint256 indexed roundId);
    event RoundClosed(uint256 indexed roundId, uint256 finalSeed, address[] honestParticipants, uint256 rewardPerPerson);

    constructor() {
        state = RoundState.Commit;
        deadline = block.number + PHASE_DURATION;
    }

    function commitTransaction(bytes32 _commitment) external payable {
        require(state == RoundState.Commit, "Not in commit phase");
        require(block.number <= deadline, "Commit phase expired");
        require(msg.value == DEPOSIT_AMOUNT, "Must deposit exactly 0.1 ETH");
        participants[msg.sender] = Participant({ commitment: _commitment, hasRevealed: false });
        participantAddresses.push(msg.sender);
    }

    function startRevealPhase() external {
        require(state == RoundState.Commit, "Not in commit phase");
        require(block.number > deadline, "Not ready to reveal");
        state = RoundState.Reveal;
        deadline = block.number + PHASE_DURATION;
        emit CommitPhaseClosed(currentRound);
    }

    function revealTransaction(uint256 _secret) external {
        require(state == RoundState.Reveal, "Not in reveal phase");
        require(block.number <= deadline, "Reveal phase expired");
        require(participants[msg.sender].commitment == keccak256(abi.encodePacked(_secret, msg.sender)), "Invalid");
        participants[msg.sender].hasRevealed = true;
        honestParticipants.push(msg.sender);
        finalSeed ^= _secret;
        (bool success, ) = payable(msg.sender).call{value: DEPOSIT_AMOUNT}("");
        require(success, "Refund failed");
    }

    function closeRound() external {
        require(state == RoundState.Reveal, "Not in reveal phase");
        require(block.number > deadline, "Reveal phase not finished");
        uint256 leftoverBounty = address(this).balance;
        if (leftoverBounty > 0 && honestParticipants.length > 0) {
            uint256 reward = leftoverBounty / honestParticipants.length;
            for (uint i = 0; i < honestParticipants.length; i++) {
                (bool success, ) = payable(honestParticipants[i]).call{value: reward}("");
                require(success, "Reward failed");
            }
        }
        emit RoundClosed(currentRound, finalSeed, honestParticipants, leftoverBounty / (honestParticipants.length > 0 ? honestParticipants.length : 1));
        for (uint i = 0; i < participantAddresses.length; i++) {
            delete participants[participantAddresses[i]];
        }
        delete participantAddresses;
        delete honestParticipants;
        finalSeed = 0;
        currentRound++;
        state = RoundState.Commit;
        deadline = block.number + PHASE_DURATION;
    }
}
