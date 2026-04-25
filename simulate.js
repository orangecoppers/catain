const { ethers } = require("ethers");

// 두 파일 모두 이 주소로 수정!
const CONTRACT_ADDRESS = "0x7969c5eD335650692Bc04293B07F5BF2e7A673C0";

async function runSimulation() {
    const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
    
    // Anvil의 첫 번째 부자 지갑 (지급용)
    const admin = await provider.getSigner(0);
    const accounts = await provider.listAccounts();
    
    console.log(`🚀 [총 ${accounts.length}명] 자금 확인 및 참여 시작...`);

    const participants = [];

    // 컨트랙트 연결
    const abi = [
        "function commitTransaction(bytes32 _commitment) external payable",
        "function revealTransaction(uint256 _secret) external"
    ];

    for (let i = 1; i < 6; i++) { // 일단 5명만 테스트해봅시다
        const userAddress = accounts[i].address;
        const userSigner = await provider.getSigner(userAddress);
        
        // 1. 돈이 없는 지갑에 1 ETH씩 쏴주기 (가스비 + 보증금)
        const balance = await provider.getBalance(userAddress);
        if (balance < ethers.parseEther("0.2")) {
            console.log(`💸 [${i}] 유저에게 자금 수송 중...`);
            await admin.sendTransaction({
                to: userAddress,
                value: ethers.parseEther("1.0")
            });
        }

        const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, userSigner);
        
        // 2. Commit 수행
        const secret = Math.floor(Math.random() * 1000000);
        const commitment = ethers.solidityPackedKeccak256(["uint256", "address"], [secret, userAddress]);
        
        console.log(`📦 [${i}] Commit 중...`);
        const tx = await contract.commitTransaction(commitment, { 
            value: ethers.parseEther("0.1") 
        });
        await tx.wait();
        
        participants.push({ secret, contract, address: userAddress });
    }

    console.log("\n✅ 5명 참여 완료! 이제 시퀀서를 확인하세요.");
    console.log("💡 'cast rpc anvil_mine 10'을 실행하면 시퀀서가 반응할 겁니다.");
}

runSimulation().catch(console.error);
