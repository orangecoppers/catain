// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FractalSequencerV4 {
    uint256 public currentRound;
    bytes32 public currentMerkleRoot;
    
    // 라운드별, 사용자별 claim 여부 확인
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    event RoundFinalized(uint256 indexed roundId, bytes32 merkleRoot);
    event Claimed(uint256 indexed roundId, address indexed user, uint256 amount);
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FractalSequencerV4 is ReentrancyGuard {
    address public sequencer;
    uint256 public currentRound;

    // roundId => merkle root
    mapping(uint256 => bytes32) public merkleRoots;

    // roundId => user => claimed
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    event RoundFinalized(uint256 indexed roundId, bytes32 merkleRoot);
    event Claimed(uint256 indexed roundId, address indexed user, uint256 amount);

    modifier onlySequencer() {
        require(msg.sender == sequencer, "Not sequencer");
        _;
    }

    constructor() {
        sequencer = msg.sender;
    }

    /**
     * @notice Finalize a round by submitting its Merkle root
     * @param _merkleRoot Root representing all user allocations
     */
    function finalizeRound(bytes32 _merkleRoot) external onlySequencer {
        merkleRoots[currentRound] = _merkleRoot;

        emit RoundFinalized(currentRound, _merkleRoot);

        currentRound++;
    }

    /**
     * @notice Claim allocated rewards using a Merkle proof
     * @param _roundId Target round to claim from
     * @param _proof Merkle proof validating inclusion
     * @param _amount Allocated reward amount
     */
    function claim(
        uint256 _roundId,
        bytes32[] calldata _proof,
        uint256 _amount
    ) external nonReentrant {
        require(_roundId < currentRound, "Invalid round");
        require(!hasClaimed[_roundId][msg.sender], "Already claimed");
        require(_amount > 0, "Invalid amount");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        require(
            MerkleProof.verify(_proof, merkleRoots[_roundId], leaf),
            "Invalid proof"
        );

        hasClaimed[_roundId][msg.sender] = true;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Claimed(_roundId, msg.sender, _amount);
    }

    /**
     * @notice Allows the contract to receive ETH for reward distribution
     */
    receive() external payable {}
}

    // 시퀀서가 라운드 결과를 요약(Merkle Root)해서 제출
    function finalizeRound(bytes32 _merkleRoot) external {
        currentMerkleRoot = _merkleRoot;
        emit RoundFinalized(currentRound, _merkleRoot);
        currentRound++;
    }

    // 사용자가 직접 Proof를 들고 와서 자기 몫을 찾아감
    function claim(bytes32[] calldata _proof, uint256 _amount) external {
        require(!hasClaimed[currentRound - 1][msg.sender], "Already claimed");

        // 유저 주소와 금액으로 Leaf 생성
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        
        // 머클 루트와 대조하여 유효성 검증
        require(MerkleProof.verify(_proof, currentMerkleRoot, leaf), "Invalid proof");

        hasClaimed[currentRound - 1][msg.sender] = true;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Claimed(currentRound - 1, msg.sender, _amount);
    }

    // 보상금 입금을 위한 receive
    receive() external payable {}
}
