/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from "ethers";
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from "@nomiclabs/hardhat-ethers/types";

import * as Contracts from ".";

declare module "hardhat/types/runtime" {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: "ERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20__factory>;
    getContractFactory(
      name: "IERC20Metadata",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20Metadata__factory>;
    getContractFactory(
      name: "IERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20__factory>;
    getContractFactory(
      name: "BaseTradeExecutor",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BaseTradeExecutor__factory>;
    getContractFactory(
      name: "ConvexHandler",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ConvexHandler__factory>;
    getContractFactory(
      name: "ConvexPositionHandler",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ConvexPositionHandler__factory>;
    getContractFactory(
      name: "Harvester",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Harvester__factory>;
    getContractFactory(
      name: "IConvexRewards",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IConvexRewards__factory>;
    getContractFactory(
      name: "ICurvePool",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ICurvePool__factory>;
    getContractFactory(
      name: "IHarvester",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IHarvester__factory>;
    getContractFactory(
      name: "IQuoter",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IQuoter__factory>;
    getContractFactory(
      name: "IUniswapSwapRouter",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IUniswapSwapRouter__factory>;
    getContractFactory(
      name: "IUniswapV3Factory",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IUniswapV3Factory__factory>;
    getContractFactory(
      name: "IUniswapV3SwapCallback",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IUniswapV3SwapCallback__factory>;
    getContractFactory(
      name: "ConvexTradeExecutor",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ConvexTradeExecutor__factory>;
    getContractFactory(
      name: "ICrossDomainMessenger",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ICrossDomainMessenger__factory>;
    getContractFactory(
      name: "OptimismWrapper",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.OptimismWrapper__factory>;
    getContractFactory(
      name: "PerpPositionHandler",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.PerpPositionHandler__factory>;
    getContractFactory(
      name: "PerpTradeExecutor",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.PerpTradeExecutor__factory>;
    getContractFactory(
      name: "ERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20__factory>;
    getContractFactory(
      name: "BasePositionHandler",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BasePositionHandler__factory>;
    getContractFactory(
      name: "ITradeExecutor",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ITradeExecutor__factory>;

    getContractAt(
      name: "ERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20>;
    getContractAt(
      name: "IERC20Metadata",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20Metadata>;
    getContractAt(
      name: "IERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20>;
    getContractAt(
      name: "BaseTradeExecutor",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BaseTradeExecutor>;
    getContractAt(
      name: "ConvexHandler",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ConvexHandler>;
    getContractAt(
      name: "ConvexPositionHandler",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ConvexPositionHandler>;
    getContractAt(
      name: "Harvester",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Harvester>;
    getContractAt(
      name: "IConvexRewards",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IConvexRewards>;
    getContractAt(
      name: "ICurvePool",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ICurvePool>;
    getContractAt(
      name: "IHarvester",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IHarvester>;
    getContractAt(
      name: "IQuoter",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IQuoter>;
    getContractAt(
      name: "IUniswapSwapRouter",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IUniswapSwapRouter>;
    getContractAt(
      name: "IUniswapV3Factory",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IUniswapV3Factory>;
    getContractAt(
      name: "IUniswapV3SwapCallback",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IUniswapV3SwapCallback>;
    getContractAt(
      name: "ConvexTradeExecutor",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ConvexTradeExecutor>;
    getContractAt(
      name: "ICrossDomainMessenger",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ICrossDomainMessenger>;
    getContractAt(
      name: "OptimismWrapper",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.OptimismWrapper>;
    getContractAt(
      name: "PerpPositionHandler",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.PerpPositionHandler>;
    getContractAt(
      name: "PerpTradeExecutor",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.PerpTradeExecutor>;
    getContractAt(
      name: "ERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20>;
    getContractAt(
      name: "BasePositionHandler",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BasePositionHandler>;
    getContractAt(
      name: "ITradeExecutor",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ITradeExecutor>;

    // default types
    getContractFactory(
      name: string,
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<ethers.ContractFactory>;
    getContractFactory(
      abi: any[],
      bytecode: ethers.utils.BytesLike,
      signer?: ethers.Signer
    ): Promise<ethers.ContractFactory>;
    getContractAt(
      nameOrAbi: string | any[],
      address: string,
      signer?: ethers.Signer
    ): Promise<ethers.Contract>;
  }
}
