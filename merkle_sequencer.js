const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { ethers } = require("ethers");

// Example participant data (replace with DB or event logs)
const participants = [
  {
    address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    amount: ethers.parseEther("0.2"),
  },
  {
    address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    amount: ethers.parseEther("0.1"),
  },
  {
    address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    amount: ethers.parseEther("0.15"),
  },
];

// Generate leaf hash (must match Solidity encoding)
function hashParticipant(address, amount) {
  return Buffer.from(
    ethers.solidityPackedKeccak256(
      ["address", "uint256"],
      [address, amount]
    ).slice(2),
    "hex"
  );
}

function buildMerkleTree(data) {
  const leaves = data.map((p) => hashParticipant(p.address, p.amount));
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  return { tree, leaves };
}

async function main() {
  const { tree } = buildMerkleTree(participants);

  const root = tree.getHexRoot();
  console.log("Merkle Root:", root);

  // Generate proofs for all users
  const proofs = participants.map((p) => {
    const leaf = hashParticipant(p.address, p.amount);
    const proof = tree.getHexProof(leaf);

    return {
      address: p.address,
      amount: p.amount.toString(),
      proof,
    };
  });

  console.log("\nProofs:");
  console.log(JSON.stringify(proofs, null, 2));

  console.log("\nNext steps:");
  console.log(`1. Call finalizeRound("${root}") on contract`);
  console.log(`2. Provide each user with their proof + amount`);
}

main().catch(console.error);
