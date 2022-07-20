//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./LyraController.sol";
import "./OptimismL2Wrapper.sol";
import "./SocketV1Controller.sol";
import "./UniswapV3Controller.sol";

import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IPositionHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BasicFeeCounter} from "@lyrafinance/protocol/contracts/periphery/BasicFeeCounter.sol";

/// @title LyraPositionHandlerL2
/// @author Bapireddy and Pradeep
/// @notice Acts as positon handler and token bridger on L2 Optimism
contract LyraPositionHandlerL2 is
    IPositionHandler,
    LyraController,
    SocketV1Controller,
    OptimismL2Wrapper,
    UniswapV3Controller
{
    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice wantTokenL2 address
    address public override wantTokenL2;

    /// @notice Address of LyraTradeExecutor on L1
    address public positionHandlerL1;

    /// @notice Address of socket registry on L2
    address public socketRegistry;

    /// @notice Keeper address
    address public keeper;

    /// @notice Governance address
    address public governance;

    /// @notice Pengin governance address
    address public pendingGovernance;

    /*///////////////////////////////////////////////////////////////
                            EVENT LOGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when keeper is updated.
    /// @param oldKeeper The address of the current keeper.
    /// @param newKeeper The address of new keeper.
    event UpdatedKeeper(address indexed oldKeeper, address indexed newKeeper);

    /// @notice Emitted when governance is updated.
    /// @param oldGovernance The address of the current governance.
    /// @param newGovernance The address of new governance.
    event UpdatedGovernance(
        address indexed oldGovernance,
        address indexed newGovernance
    );

    /// @notice Emitted when socket registry is updated.
    /// @param oldRegistry The address of the current Registry.
    /// @param newRegistry The address of new Registry.
    event UpdatedSocketRegistry(
        address indexed oldRegistry,
        address indexed newRegistry
    );

    /// @notice Emitted when slippage is updated.
    /// @param oldSlippage The current slippage.
    /// @param newSlippage Newnew slippage.
    event UpdatedSlippage(uint256 oldSlippage, uint256 newSlippage);

    /*///////////////////////////////////////////////////////////////
                            INITIALIZING
    //////////////////////////////////////////////////////////////*/
    // @TODO: remove _lyraRegistry
    constructor(
        address _wantTokenL2,
        address _positionHandlerL1,
        address _lyraOptionMarket,
        address _keeper,
        address _governance,
        address _socketRegistry,
        uint256 _slippage,
        address _lyraRegistry,
        address _sUSD
    ) {
        wantTokenL2 = _wantTokenL2;
        positionHandlerL1 = _positionHandlerL1;
        keeper = _keeper;
        socketRegistry = _socketRegistry;

        slippage = _slippage;
        governance = _governance;

        _configHandler(_lyraOptionMarket);

        // approve max want token L2 balance to uniV3 router
        IERC20(wantTokenL2).approve(
            address(UniswapV3Controller.uniswapRouter),
            type(uint256).max
        );
        // approve max susd balance to uniV3 router
        LyraController.sUSD.approve(
            address(UniswapV3Controller.uniswapRouter),
            type(uint256).max
        );

        // deploy basic fee counter and set trusted counter
        BasicFeeCounter feeCounter = new BasicFeeCounter();
        feeCounter.setTrustedCounter(address(this), true);

        // set Lyra Adapter
        LyraAdapter.setLyraAddresses(
            _lyraRegistry,
            _lyraOptionMarket,
            0xA5407eAE9Ba41422680e2e00537571bcC53efBfD,
            // fee counter
            address(feeCounter)
        );

        // set UniswapV3Controller config
        UniswapV3Controller._setConfig(_sUSD);
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function positionInWantToken()
        public
        view
        override
        returns (uint256, uint256)
    {
        /// Get balance in susd and convert it into USDC
        uint256 sUSDBalance = LyraController._positionInWantToken();
        uint256 USDCPriceInsUSD = UniswapV3Controller._getUSDCPriceInSUSD();

        /// Adding USDC balance of contract as wantToken is wrapped USDC
        return (
            (sUSDBalance * USDC_NORMALIZATION_FACTOR) /
                USDCPriceInsUSD +
                IERC20(wantTokenL2).balanceOf(address(this)),
            block.number
        );
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT / WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Converts the whole wantToken to sUSD.
    function deposit() public override onlyKeeper {
        require(
            IERC20(wantTokenL2).balanceOf(address(this)) > 0,
            "INSUFFICIENT_BALANCE"
        );

        UniswapV3Controller._estimateAndSwap(
            true,
            IERC20(wantTokenL2).balanceOf(address(this))
        );
    }

    /// @notice Bridges wantToken back to strategy on L1
    /// @dev Check MovrV1Controller for more details on implementation of token bridging
    /// @param amountOut amount needed to be sent to strategy
    /// @param _socketRegistry address of movr contract to send txn to
    /// @param socketData movr txn calldata
    function withdraw(
        uint256 amountOut,
        address _socketRegistry,
        bytes calldata socketData
    ) public override onlyAuthorized {
        require(
            IERC20(wantTokenL2).balanceOf(address(this)) >= amountOut,
            "NOT_ENOUGH_TOKENS"
        );
        require(socketRegistry == _socketRegistry, "INVALID_REGISTRY");
        SocketV1Controller.sendTokens(
            wantTokenL2,
            socketRegistry,
            positionHandlerL1,
            amountOut,
            1,
            socketData
        );
    }

    /*///////////////////////////////////////////////////////////////
                        OPEN / CLOSE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Purchases new option on lyra.
    /// @dev Will use all sUSD balance to purchase option on Lyra.
    /// @param strikeId Strike ID of the option based on strike price
    /// @param isCall boolean indication call or put option to purchase.
    /// @param amount amount of options to buy
    /// @param updateExistingPosition boolean indication of if existing position should be updated
    function openPosition(
        uint256 strikeId,
        bool isCall,
        uint256 amount,
        bool updateExistingPosition
    )
        public
        override
        onlyAuthorized
        returns (LyraAdapter.TradeResult memory tradeResult)
    {
        tradeResult = LyraController._openPosition(
            strikeId,
            isCall,
            amount,
            updateExistingPosition
        );
    }

    /// @notice Exercises/Sell option on lyra.
    /// @dev Will sell back or settle the option on Lyra.
    /// @param toSettle boolean if true settle position, else close position
    function closePosition(bool toSettle) public override onlyAuthorized {
        LyraController._closePosition(toSettle);
        // @TODO: UNCOMMENT THIS
        // UniswapV3Controller._estimateAndSwap(
        //   false,
        //   LyraController.sUSD.balanceOf(address(this))
        // );
    }

    // @TODO: REMOVE
    function mintNewPosition(
        address token0,
        address token1,
        uint256 amount0ToMint,
        uint256 amount1ToMint,
        uint24 poolFee
    )
        external
        onlyAuthorized
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // Approve the position manager
        IERC20(token0).approve(
            address(nonfungiblePositionManager),
            amount0ToMint
        );
        IERC20(token1).approve(
            address(nonfungiblePositionManager),
            amount1ToMint
        );

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: poolFee,
                tickLower: int24(-887272),
                tickUpper: int24(887272),
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);
    }

    /*///////////////////////////////////////////////////////////////
                            MAINTAINANCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sweep tokens
    /// @param _token Address of the token to sweepr
    function sweep(address _token) public override onlyGovernance {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /// @notice slippage setter
    /// @param _slippage updated slippage value
    function setSlippage(uint256 _slippage) public onlyGovernance {
        emit UpdatedSlippage(slippage, _slippage);
        slippage = _slippage;
    }

    /// @notice socket registry setter
    /// @param _socketRegistry new address of socket registry
    function setSocketRegistry(address _socketRegistry) public onlyGovernance {
        emit UpdatedSocketRegistry(socketRegistry, _socketRegistry);
        socketRegistry = _socketRegistry;
    }

    /// @notice keeper setter
    /// @param _keeper new keeper address
    function setKeeper(address _keeper) public onlyGovernance {
        emit UpdatedKeeper(keeper, _keeper);
        keeper = _keeper;
    }

    /// @notice Governance setter
    /// @param _pendingGovernance new governance address
    function setGovernance(address _pendingGovernance) public onlyGovernance {
        pendingGovernance = _pendingGovernance;
    }

    /// @notice Governance accepter
    function acceptGovernance() public {
        require(msg.sender == pendingGovernance, "NOT_PENDING_GOVERNANCE");
        emit UpdatedGovernance(governance, pendingGovernance);
        governance = pendingGovernance;
    }

    /// @notice checks wether txn sender is keeper address or LyraTradeExecutor using optimism gateway
    modifier onlyAuthorized() {
        require(
            ((msg.sender == L2CrossDomainMessenger &&
                OptimismL2Wrapper.messageSender() == positionHandlerL1) ||
                msg.sender == keeper),
            "ONLY_AUTHORIZED"
        );
        _;
    }

    /// @notice only keeper can call this function
    modifier onlyKeeper() {
        require(msg.sender == keeper, "ONLY_KEEPER");
        _;
    }

    /// @notice only governance can call this function
    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }
}
