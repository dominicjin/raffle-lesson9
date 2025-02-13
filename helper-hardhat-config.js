const { ethers } = require("hardhat")

const networkConfig = {
    11155111: {
        name: "sepolia",
        // vrfCoordinator: "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B",
        vrfCoordinator: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
        gasLane:
            "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
        entranceFee: ethers.parseEther("0.01"),
        subscriptionId:
            "58234548930115356777277397313968886605635719388980747066876407031642209005897",
        callbackGasLimit: "500000",
        interval: "30",
    },
    31337: {
        name: "hardhat",
        // vrfCoordinator: "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B",
        entranceFee: ethers.parseEther("0.01"),
        gasLane:
            "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
        subscriptionId: "0",
        callbackGasLimit: "500000",
        interval: "30",
    },
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
}
