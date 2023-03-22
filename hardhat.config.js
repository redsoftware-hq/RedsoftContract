require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  networks: {
		hardhat: {
			chainId: 1337,
		},
		matic: {
			url: "https://polygon-mumbai.g.alchemy.com/v2/giD3tit0dw8BuMael4GlN8-zS-MdDgD0",
			accounts: ["b06ea989491e4e194e9c46981c690e88aaeaeac101ef49f0ad65a157962cdeee"]
		},
	},
  solidity: "0.8.18",
};
