const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")

const BASE_FEE = ethers.parseEther("0.25") // 20%
const GAS_PRICE_LINK = 1e9 // link per gas
const WEIPERUNITLINK = 1

module.exports = async ({ deployments }) => {
    const { deploy, log } = deployments
    const deployer = (await ethers.getSigners())[0]
    const chainId = network.config.chainId

    const args = [BASE_FEE, GAS_PRICE_LINK, WEIPERUNITLINK]

    if (developmentChains.includes(network.name)) {
        log("Local network detected! Deploying mocks...")
        // deploy a mock vrfcoordinator
        console.log(deployer)
        await deploy("VRFCoordinatorV2_5Mock", {
            from: deployer.address,
            log: true,
            args: args,
        })

        log("Mocks Deployed")
        log("---------------------------------")
    }
}

module.exports.tags = ["all", "mock"]
