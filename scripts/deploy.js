async function main() {
  const dreamDappFactory = await ethers.getContractFactory("DreamDapp");

  // Start deployment, returning a promise that resolves to a contract object
  const dreamDapp = await dreamDappFactory.deploy();
  console.log("Contract deployed to address:", dreamDapp.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
//
