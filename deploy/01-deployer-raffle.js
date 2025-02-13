const { network, ethers, deployments } = require("hardhat")
const {
    developmentChains,
    networkConfig,
    verify,
} = require("../helper-hardhat-config")

const VRF_SUB_FUND_AMOUNT = ethers.parseEther("30")

module.exports = async function () {
    const { deploy, log } = deployments
    const deployer = (await ethers.getSigners())[0]
    const chainId = network.config.chainId
    let vrfCoordinatorAddress, subscriptionId, vrfCoordinateDeployment

    if (developmentChains.includes(network.name)) {
        vrfCoordinateDeployment = await deployments.get(
            "VRFCoordinatorV2_5Mock",
        )
        const vrfCoordinatorMock = await ethers.getContractAt(
            vrfCoordinateDeployment.abi,
            vrfCoordinateDeployment.address,
            deployer,
        )
        vrfCoordinatorAddress = vrfCoordinatorMock.target
        // console.log(vrfCoordinatorAddress)
        const transactionResponse =
            await vrfCoordinatorMock.createSubscription()
        // console.log(transactionResponse)
        const transactionReceipt = await transactionResponse.wait(1)
        console.log(transactionReceipt.logs)
        // console.log(transactionResponse)

        subscriptionId = transactionReceipt.logs[0].topics[1]
        console.log(subscriptionId)
        // fund
        // link token
        await vrfCoordinatorMock.fundSubscription(
            subscriptionId,
            VRF_SUB_FUND_AMOUNT,
        )
    } else {
        vrfCoordinatorAddress = networkConfig[chainId]["vrfCoordinatorV2"]
        subscriptionId = networkConfig[chainId]["subscriptionId"]
    }
    console.log("success")
    console.log(chainId)
    const entranceFee = networkConfig[chainId]["entranceFee"]
    const gasLane = networkConfig[chainId]["gasLane"]
    console.log(gasLane)
    const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"]
    const interval = networkConfig[chainId]["interval"]

    const args = [
        vrfCoordinatorAddress,
        entranceFee,
        gasLane,
        subscriptionId,
        callbackGasLimit,
        interval,
    ]

    const raffle = await deploy("Raffle", {
        from: deployer.address,
        args: args,
        log: true,
        waitConfirmations: network.config.waitConfirmations || 1,
    })

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        log("Verifying")
        await verify(raffle.address, args)
    }
    log("------------------------------------")
}

module.exports.tags = ["all", "raffle"]
