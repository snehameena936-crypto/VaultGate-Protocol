const { ethers } = require("hardhat");

async function main() {
  const VaultGateProtocol = await ethers.getContractFactory("VaultGateProtocol");
  const vaultGateProtocol = await VaultGateProtocol.deploy();

  await vaultGateProtocol.deployed();

  console.log("VaultGateProtocol contract deployed to:", vaultGateProtocol.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
