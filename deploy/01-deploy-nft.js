const { network } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const chainId = network.config.chainId

    let mintFee, subscriptionId, vrfCoordinatorV2Address, keyHash, callbackGasLimit

    log("-------------------")

    if (!developmentChains.includes(network.name)) {
        mintFee = networkConfig[chainId].mintFee
        subscriptionId = networkConfig[chainId].subscriptionId
        vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2
        keyHash = networkConfig[chainId].keyHash
        callbackGasLimit = networkConfig[chainId].callbackGasLimit
    }

    const args = [mintFee, vrfCoordinatorV2Address, subscriptionId, keyHash, callbackGasLimit]
    const BasicNFT = await deploy("Raccoons", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 3,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(BasicNFT.address, args)
    }

    log("-------------------")
}
