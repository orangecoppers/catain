require("dotenv").config();
const { ethers } = require("ethers");

const RPC_URL = process.env.RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;

const ABI = [
  "function state() view returns (uint8)",
  "function deadline() view returns (uint256)",
  "function startRevealPhase() external",
  "function closeRound() external",
  "event RoundClosed(uint256 indexed roundId, uint256 finalSeed, address[] participants)"
];

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

  console.log("Sequencer started...");

  let lastActionBlock = 0;

  setInterval(async () => {
    try {
      const blockNumber = await provider.getBlockNumber();

      // 너무 자주 실행 방지
      if (blockNumber === lastActionBlock) return;

      const state = Number(await contract.state());
      const deadline = Number(await contract.deadline());

      process.stdout.write(
        `\rBlock: ${blockNumber} | Deadline: ${deadline} | State: ${
          state === 0 ? "Commit" : "Reveal"
        }`
      );

      // Commit → Reveal
      if (state === 0 && blockNumber > deadline) {
        console.log("\nTransition: Commit → Reveal");

        const tx = await contract.startRevealPhase();
        await tx.wait();

        lastActionBlock = blockNumber;
        console.log("Reveal phase started");
      }

      // Reveal → Close
      if (state === 1 && blockNumber > deadline) {
        console.log("\nTransition: Reveal → Close");

        const tx = await contract.closeRound();
        await tx.wait();

        lastActionBlock = blockNumber;
        console.log("Round closed");
      }
    } catch (err) {
      console.error("\nError:", err.reason || err.message);
    }
  }, 1000);

  contract.on("RoundClosed", (roundId, finalSeed, participants) => {
    console.log(`\nRound ${roundId} finalized`);
    participants.forEach((p, i) => {
      console.log(`[${i + 1}] ${p}`);
    });
    console.log("----------------------------");
  });
}

main().catch(console.error);
