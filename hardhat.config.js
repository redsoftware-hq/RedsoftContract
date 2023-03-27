require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  networks: {
		hardhat: {
			chainId: 1337,
		},
		matic: {
			url: "https://polygon-mumbai.g.alchemy.com/v2/giD3tit0dw8BuMael4GlN8-zS-MdDgD0",
			accounts: ["1ce99cdc8186e4fb45c60e8e72b530dfed2b28b1f1754589bcd0405a00bc02dc"]
		},
	},
  solidity: "0.8.18",
};
