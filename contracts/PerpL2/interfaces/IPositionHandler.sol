/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6 <0.8.10;

interface IPositionHandler {

    /// @notice Creates a new position on Perp V2
    /// @dev Will deposit all USDC balance to Perp. Will close any existing position, then open a position with given amountIn on Perp.
    /// @param _amount the amountIn with respect to free collateral on perp for new position
    /// @param _slippage slippage while opening position, calculated out of 10000
    function openPosition(
        bool _isShort,
        uint256 _amount,
        uint24 _slippage
    ) external;


    /// @notice Closes existing position on Perp V2
    /// @dev Closes the position, withdraws all the funds from perp as well.
    /// @param _slippage slippage while closing position, calculated out of 10000
    function closePosition(uint24 _slippage) external;

    /// @notice Bridges wantToken back to strategy on L1
    /// @dev Check MovrV1Controller for more details on implementation of token bridging
    /// @param amountOut amount needed to be sent to strategy
    /// @param allowanceTarget address of contract to provide ERC20 allowance to
    /// @param socketRegistry address of movr contract to send txn to
    /// @param socketData movr txn calldata
    function withdraw(uint256 amountOut, address allowanceTarget, address socketRegistry, bytes calldata socketData) external;

    /// @notice Sweep tokens 
    /// @param _token Address of the token to sweep
    function sweep(address _token) external;
}

