// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {
    FlashLoanReceiverBase
} from "./aave/flashloan/base/FlashLoanReceiverBase.sol";
import {ILendingPool} from "./aave/interfaces/ILendingPool.sol";
import {
    ILendingPoolAddressesProvider
} from "./aave/interfaces/ILendingPoolAddressesProvider.sol";
import {IERC20} from "./openzeppelin/contracts/IERC20.sol";
import {IERC20Detailed} from "./openzeppelin/contracts/IERC20Detailed.sol";
import {
    ReserveConfiguration
} from "./aave/protocol/libraries/configuration/ReserveConfiguration.sol";
import {
    UserConfiguration
} from "./aave/protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "./aave/protocol/libraries/types/DataTypes.sol";
// import {IOneSplit} from "./1inch/IOneSplit.sol";

contract Bot is FlashLoanReceiverBase {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    address constant aaveEthAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // IOneSplit oneSplit;

    constructor(address _addressProvider, address _onesplitAddress)
        public
        FlashLoanReceiverBase(ILendingPoolAddressesProvider(_addressProvider))
    {
        // oneSplit = IOneSplit(_onesplitAddress);
    }

    function triggerStopLoss(
        address _collateralAsset,
        address _debtAsset,
        address _user,
        uint256 _takeProfit,
        uint256 _stopLoss
    ) public {
        // find if debt asset price is below stopLoss using chainlink

        DataTypes.ReserveData memory reserve =
            ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getReserveData(
                _debtAsset
            );
        DataTypes.UserConfigurationMap memory userConfig =
            ILendingPool(ADDRESSES_PROVIDER.getLendingPool())
                .getUserConfiguration(_user);
        uint256 currentATokenBalance =
            IERC20Detailed(reserve.aTokenAddress).balanceOf(_user);
        bool usageAsCollateralEnabled =
            userConfig.isUsingAsCollateral(reserve.id);
        uint256 rateMode = 0; // todo
        require(usageAsCollateralEnabled, "usageAsCollateralEnabled is false");

        uint256 debtAmount = currentATokenBalance;

        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = _debtAsset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = debtAmount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](2);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = abi.encode(_collateralAsset, _user, rateMode);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function executeOperation(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address _initiator,
        bytes calldata _params
    ) external override returns (bool) {
        (address collateralAsset, address user, uint256 rateMode) =
            abi.decode(_params, (address, address, uint256));

        uint256 debtAmount = _amounts[0];
        address debtAsset = _assets[0];
        uint256 flashPremium = _premiums[0];

        // repay debt
        LENDING_POOL.repay(debtAsset, debtAmount, rateMode, user);

        // // swap user's collateral to debt using 1inch api
        // uint256 quoteMinReturn = 0;
        // uint256[] memory quoteDistribution = [];
        // uint256 quoteFlags = 0;
        // oneSplit.swap(
        //     collateralAsset,
        //     debtAsset,
        //     debtAmount,
        //     quoteMinReturn,
        //     quoteDistribution,
        //     quoteFlags
        // );

        // repay flash loan
        uint256 flashLoanOwing = debtAmount.add(flashPremium);
        IERC20(debtAsset).approve(address(LENDING_POOL), flashLoanOwing);

        return true;
    }
}
