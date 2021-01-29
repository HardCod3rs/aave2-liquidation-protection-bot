import * as ethers from 'ethers';
import Big from 'big.js';
import BOT_BUILD from '../build/contracts/Bot.json';
import LENDING_POOL_CONTRACT_BUILD from '../build/contracts/ILendingPool.json';

const CHAIN_ID = '1';
const LENDING_POOL_ADDRESS = '0x398ec7346dcd622edc5ae82352f02be94c62d119';

main().then(
  () => process.exit(),
  (err: Error) => {
    console.log(err);
    process.exit(-1);
  }
);

async function main(): Promise<void> {
  const collateralAddress = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
  const reserveAddress = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
  const userAddress = '0x864289124bb9de5a2c4f265568ac939c98023e13';
  const takeProfit = 0;
  const stopLoss = 0;

  await monitor(
    collateralAddress,
    reserveAddress,
    userAddress,
    takeProfit,
    stopLoss
  );
}

async function monitor(
  collateralAddress: string,
  reserveAddress: string,
  userAddress: string,
  stopLoss: number,
  takeProfit: number
): Promise<void> {
  const provider = new ethers.providers.JsonRpcProvider(
    'http://127.0.0.1:8545'
  );

  const { address: botAddress } = BOT_BUILD.networks[CHAIN_ID];
  const bot = new ethers.Contract(
    botAddress,
    BOT_BUILD.abi,
    provider.getSigner()
  );

  const lendingPool = new ethers.Contract(
    LENDING_POOL_ADDRESS,
    LENDING_POOL_CONTRACT_BUILD.abi,
    provider.getSigner()
  );

  console.log(
    await bot.monitor(
      collateralAddress,
      reserveAddress,
      userAddress,
      takeProfit,
      stopLoss
    )
  );
  console.log(
    big(
      (
        await lendingPool.getUserAccountData(userAddress)
      ).healthFactor.toString()
    )
      .div(1e18)
      .toFixed(4),
    big((await provider.getBalance(botAddress)).toString())
      .div(1e18)
      .toFixed(4)
  );
}

function big(num: string): typeof Big {
  return new Big(num);
}
