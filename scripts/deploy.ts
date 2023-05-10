import { ethers} from 'hardhat';
const hre = require("hardhat");
import console from 'console';
const fs = require('fs');
const fse = require("fs-extra");
const { verify } = require('../utils/verify')
const { getAmountInWei, developmentChains } = require('../utils/helper-scripts');

const _metadataUri = 'https://gateway.pinata.cloud/ipfs/https://gateway.pinata.cloud/ipfs/QmX2ubhtBPtYw75Wrpv6HLb1fhbJqxrnbhDo1RViW3oVoi';

async function deploy(name: string, ...params: [string]) {
  const contractFactory = await ethers.getContractFactory(name);

  return await contractFactory.deploy(...params).then((f) => f.deployed());
}

async function main() {
  const deployNetwork = hre.network.name;

  const [admin] = await ethers.getSigners();
  
  console.log(`Deploying a smart contract...`);

  const AVAXGods = (await deploy('AVAXGods', _metadataUri)).connect(admin);

  


  // Deploy SluppyToken ERC20 token contract 
  const TokenContract = await ethers.getContractFactory("SluppyToken");
  const tokenContract = await TokenContract.deploy();

  await tokenContract.deployed();


  // Deploy NFTStakingVault contract 
  const Vault = await ethers.getContractFactory("NFTStakingVault");
  const stakingVault = await Vault.deploy(AVAXGods.address, tokenContract.address);

  await stakingVault.deployed();

  const control_tx = await tokenContract.setController(stakingVault.address, true)
  await control_tx.wait()

  /* console.log({ AVAXGods: AVAXGods.address }); */
  console.log("AVAXgods NFT contract deployed at:\n", AVAXGods.address);
  console.log("SluppyToken ERC20 token contract deployed at:\n", tokenContract.address);
  console.log("NFT Staking Vault deployed at:\n", stakingVault.address);
  console.log("Network deployed to :\n", deployNetwork);

  /* transfer contracts addresses & ABIs to the front-end */
  if (fs.existsSync("../client/src")) {
    fs.rmSync("../src/contract", { recursive: true, force: true });
    fse.copySync("./contracts", "../client/src/contract")
    fs.writeFileSync("../client/src/contract/index.js", `
      export const stakingContractAddress = "${stakingVault.address}"
      export const nftContractAddress = "${AVAXGods.address}"
      export const tokenContractAddress = "${tokenContract.address}"
      export const ownerAddress = "${admin}"
      export const networkDeployedTo = "${hre.network.config.chainId}"
    `)
  }


  if (!developmentChains.includes(deployNetwork) && hre.config.etherscan.apiKey[deployNetwork]) {
    console.log("waiting for 6 blocks verification ...")
    await stakingVault.deployTransaction.wait(6)

    // args represent contract constructor arguments
    const args = [AVAXGods.address, tokenContract.address]
    await verify(stakingVault.address, args)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  });
