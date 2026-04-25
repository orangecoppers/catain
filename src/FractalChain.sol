// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FractalSequencer {
    address public sequencer;
    uint256 public currentRound;

    enum RoundState {
        Commit,
        Reveal
    }

    RoundState public state;

    uint256 public combinedSeed;
    address[] public participants;

    mapping(uint256 => mapping(address => bool)) public hasCommitted;
    mapping(uint256 => mapping(address => bytes32)) public commitments;
    mapping(uint256 => mapping(address => bool)) public hasRevealed;

    event CommitPhaseClosed(uint256 indexed roundId);
    event RoundClosed(uint256 indexed roundId, uint256 finalSeed, address[] participants);

    modifier onlySequencer() {
        require(msg.sender == sequencer, "Not sequencer");
        _;
    }

    constructor() {
        sequencer = msg.sender;
        state = RoundState.Commit;
    }

    /**
     * @notice Submit a commitment during the commit phase
     * @param _commitment Hash of (secret, sender)
     */
    function commitTransaction(bytes32 _commitment) external {
        require(state == RoundState.Commit, "Invalid phase");
        require(!hasCommitted[currentRound][msg.sender], "Already committed");

        hasCommitted[currentRound][msg.sender] = true;
        commitments[currentRound][msg.sender] = _commitment;

        participants.push(msg.sender);
    }

    /**
     * @notice Transition to reveal phase
     */
    function startRevealPhase() external onlySequencer {
        require(state == RoundState.Commit, "Invalid phase");

        state = RoundState.Reveal;
        emit CommitPhaseClosed(currentRound);
    }

    /**
     * @notice Reveal secret to contribute to randomness
     * @param _secret Original secret used in commitment
     */
    function revealTransaction(uint256 _secret) external {
        require(state == RoundState.Reveal, "Invalid phase");
        require(hasCommitted[currentRound][msg.sender], "No commitment");
        require(!hasRevealed[currentRound][msg.sender], "Already revealed");

        bytes32 expected = keccak256(abi.encodePacked(_secret, msg.sender));
        require(commitments[currentRound][msg.sender] == expected, "Invalid reveal");

        hasRevealed[currentRound][msg.sender] = true;

        combinedSeed ^= _secret;
    }

    /**
     * @notice Finalize the round and emit result
     */
    function closeRound() external onlySequencer {
        require(state == RoundState.Reveal, "Invalid phase");

        uint256 finalSeed = combinedSeed;

        emit RoundClosed(currentRound, finalSeed, participants);

        currentRound++;
        delete participants;
        combinedSeed = 0;
        state = RoundState.Commit;
    }
}
