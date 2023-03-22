const hre = require("hardhat");
const fs = require("fs");

async function main() {
	const market = await hre.ethers.getContractFactory("RedsoftContract");
	const nft = await market.deploy();
	await nft.deployed();

	const data = {
		address: nft.address,
		abi: JSON.parse(nft.interface.format("json")),
	};

	fs.writeFileSync("Marketplace.json", JSON.stringify(data));

	console.log(`Deployed NFT Contract at: ${nft.address}`);
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});