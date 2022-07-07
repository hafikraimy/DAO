const { ethers } = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants");

async function main() {
  const fakeNFTMarketplaceContract = await ethers.getContractFactory(
    "FakeNFTMarketplace"
  );

  const deployedFakeNFTMarketplaceContract = await fakeNFTMarketplaceContract.deploy();
  await deployedFakeNFTMarketplaceContract.deployed();

  console.log("FakeNFTMarketplace deployed to: ", deployedFakeNFTMarketplaceContract.address);

  const cryptoDevsDAOContract = await ethers.getContractFactory("CryptoDevsDAO");
  const deployedCryptoDevsDAOContract = await cryptoDevsDAOContract.deploy(
    deployedFakeNFTMarketplaceContract.address,
    CRYPTODEVS_NFT_CONTRACT_ADDRESS,
    {
        // this assume your account has at least 0.1 ETH 
        value: ethers.utils.parseEther("0.1")
    }
  ); 

  await deployedCryptoDevsDAOContract.deployed();

  console.log("CryptoDevsDAO deployed to: ", deployedCryptoDevsDAOContract.address)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.log(err);
    process.exit(1);
  });
