const Bot = artifacts.require('Bot');

module.exports = async function (deployer) {
  const lendingPoolAddressesProviderAddress =
    '0xb53c1a33016b2dc2ff3653530bff1848a515c8c5';
  const oneSplitAddress = '0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E';
  await deployer.deploy(
    Bot,
    lendingPoolAddressesProviderAddress,
    oneSplitAddress
  );
};
