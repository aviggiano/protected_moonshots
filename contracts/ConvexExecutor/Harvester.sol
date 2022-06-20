/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IHarvester.sol";
import "../../interfaces/IVault.sol";
import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/ICurveV2Pool.sol";
import "../../interfaces/IAggregatorV3.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Harvester
/// @author PradeepSelva
/// @notice A contract to harvest rewards from Convex staking position into Want TOken
contract Harvester is IHarvester {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    /*///////////////////////////////////////////////////////////////
                        GLOBAL CONSTANTS
  //////////////////////////////////////////////////////////////*/
    /// @notice desired uniswap fee
    uint24 public constant UNISWAP_FEE = 500;
    /// @notice the max basis points used as normalizing factor
    uint256 public constant MAX_BPS = 1000;
    /// @notice normalization factor for decimals
    uint256 public constant USD_NORMALIZATION_FACTOR = 1e8;
    /// @notice normalization factor for decimals
    uint256 public constant ETH_NORMALIZATION_FACTOR = 1e18;

    /// @notice address of crv token
    IERC20 public constant override crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    /// @notice address of cvx token
    IERC20 public constant override cvx =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    /// @notice address of 3CRV LP token
    IERC20 public constant override _3crv =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    /// @notice address of WETH token
    IERC20 private constant weth =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice address of Curve's CRV/ETH pool
    ICurveV2Pool private constant crveth =
        ICurveV2Pool(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    /// @notice address of Curve's CVX/ETH pool
    ICurveV2Pool private constant cvxeth =
        ICurveV2Pool(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    /// @notice address of Curve's 3CRV metapool
    ICurveV2Pool private constant _3crvPool =
        ICurveV2Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    /// @notice address of uniswap router
    IUniswapV3Router private constant uniswapRouter =
        IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice chainlink data feed for CRV/USD
    IAggregatorV3 public constant crvUsdPrice =
        IAggregatorV3(0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f);
    /// @notice chainlink data feed for CVX/USD
    IAggregatorV3 public constant cvxUsdPrice =
        IAggregatorV3(0xd962fC30A72A84cE50161031391756Bf2876Af5D);
    /// @notice chainlink data feed for LDO/USD
    IAggregatorV3 public constant ethUsdPrice =
        IAggregatorV3(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /*///////////////////////////////////////////////////////////////
                        MUTABLE ACCESS MODFIERS
  //////////////////////////////////////////////////////////////*/
    /// @notice instance of vault
    IVault public override vault;
    /// @notice maximum acceptable slippage
    uint256 public maxSlippage = 1000;

    /// @notice creates a new Harvester
    /// @param _vault address of vault
    constructor(address _vault) {
        vault = IVault(_vault);

        // max approve CRV to CRV/ETH pool on curve
        crv.approve(address(crveth), type(uint256).max);
        // max approve CVX to CVX/ETH pool on curve
        cvx.approve(address(cvxeth), type(uint256).max);
        // max approve WETH to uniswap router
        weth.approve(address(uniswapRouter), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                         VIEW FUNCTONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Function which returns address of reward tokens
    /// @return rewardTokens array of reward token addresses
    function rewardTokens() external pure override returns (address[] memory) {
        address[] memory rewards = new address[](3);
        rewards[0] = address(crv);
        rewards[1] = address(cvx);
        rewards[2] = address(_3crv);
        return rewards;
    }

    /*///////////////////////////////////////////////////////////////
                    KEEPER FUNCTONS
  //////////////////////////////////////////////////////////////*/
    /// @notice Keeper function to set maximum slippage
    /// @param _slippage new maximum slippage
    function setSlippage(uint256 _slippage) external override onlyKeeper {
        maxSlippage = _slippage;
    }

    /*///////////////////////////////////////////////////////////////
                      GOVERNANCE FUNCTIONS
  //////////////////////////////////////////////////////////////*/
    /// @notice Governance function to sweep a token's balance lying in Harvester
    /// @param _token address of token to sweep
    function sweep(address _token) external override onlyGovernance {
        IERC20(_token).safeTransfer(
            vault.governance(),
            IERC20Metadata(_token).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                    STATE MODIFICATION FUNCTONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Harvest the entire swap tokens list, i.e convert them into wantToken
    /// @dev Pulls all swap token balances from the msg.sender, swaps them into wantToken, and sends back the wantToken balance
    function harvest() external override {
        uint256 crvBalance = crv.balanceOf(address(this));
        uint256 cvxBalance = cvx.balanceOf(address(this));
        uint256 _3crvBalance = _3crv.balanceOf(address(this));
        // swap convex to eth
        if (cvxBalance > 0) {
            uint256 expectedEth = (cvxBalance * _getPrice(cvxUsdPrice)) /
                USD_NORMALIZATION_FACTOR;

            cvxeth.exchange(
                1,
                0,
                cvxBalance,
                _getMinReceived(expectedEth),
                false
            );
        }
        // swap crv to eth
        if (crv.balanceOf(address(this)) > 0) {
            uint256 expectedEth = (crvBalance * _getPrice(crvUsdPrice)) /
                USD_NORMALIZATION_FACTOR;

            crveth.exchange(
                1,
                0,
                crvBalance,
                _getMinReceived(expectedEth),
                false
            );
        }
        uint256 wethBalance = weth.balanceOf(address(this));

        // swap eth to USDC using 0.5% pool
        if (wethBalance > 0) {
            uniswapRouter.exactInput(
                IUniswapV3Router.ExactInputParams(
                    abi.encodePacked(
                        address(weth),
                        uint24(UNISWAP_FEE),
                        address(vault.wantToken())
                    ),
                    address(this),
                    block.timestamp,
                    wethBalance,
                    (((_getPrice(ethUsdPrice) * wethBalance) /
                        ETH_NORMALIZATION_FACTOR) * maxSlippage) / MAX_BPS
                )
            );
        }

        // swap _crv to usdc
        if (_3crvBalance > 0) {
            _3crvPool.remove_liquidity_one_coin(_3crvBalance, 1, 0);
        }

        // send token usdc back to vault
        IERC20(vault.wantToken()).safeTransfer(
            msg.sender,
            IERC20(vault.wantToken()).balanceOf(address(this))
        );
    }

    /// @notice helper to get price of tokens from chainlink
    /// @param priceFeed the price feed to fetch latest price from
    function _getPrice(IAggregatorV3 priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();
        return uint256(latestPrice);
    }

    /// @notice helper to get minimum amount to receive from swap
    function _getMinReceived(uint256 amount) internal view returns (uint256) {
        return (amount * maxSlippage) / MAX_BPS;
    }

    /*///////////////////////////////////////////////////////////////
                        ACCESS MODIFIERS
  //////////////////////////////////////////////////////////////*/

    /// @notice to check for valid address
    modifier validAddress(address _addr) {
        require(_addr != address(0), "_addr invalid");
        _;
    }

    /// @notice to check if caller is governance
    modifier onlyGovernance() {
        require(
            msg.sender == vault.governance(),
            "Harvester :: onlyGovernance"
        );
        _;
    }

    /// @notice to check if caller is keeper
    modifier onlyKeeper() {
        require(msg.sender == vault.keeper(), "auth: keeper");
        _;
    }
}
