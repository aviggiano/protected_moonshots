import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import hre, { ethers } from "hardhat";
import { wantTokenL1 } from "../../scripts/constants";
import {
  ConvexTradeExecutor,
  Harvester,
  Vault,
  IConvexRewards,
  IERC20
} from "../../src/types";
import { getUSDCContract, mineBlocks, setup } from "../utils";

const ConvexTradeExecutorConfig = {
  baseRewardPool: "0x7e2b9B5244bcFa5108A76D5E7b507CFD5581AD4A",
  convexBooster: "0xF403C135812408BFbE8713b5A23a04b3D48AAE31",
  ust3Pool: "0xCEAF7747579696A2F0bb206a14210e3c9e6fB269",
  curve3PoolZap: "0xA79828DF1850E8a3A3064576f380D90aECDD3359"
};

const HarvesterConfig = {
  wantToken: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
};

const DeployedAddresses = {
  convexTradeExec: "0x3167b932336b029bBFE1964E435889FA8e595738",
  harvester: "0xF1D339D9456BC1e09b548E7946A78D9C4b5f1B68",
  vault: "0x1C4ceb52ab54a35F9d03FcC156a7c57F965e081e"
};

const MAX_INT =
  "115792089237316195423570985008687907853269984665640564039457584007913129639935";
const CRV_ADDR = "0xD533a949740bb3306d119CC777fa900bA034cd52";
const CVX_ADDR = "0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B";
const _3CRV_ADDR = "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490";
const CRVETH = "0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511";
const CVXETH = "0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4";
const _3CRVPOOL = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";

let convexTradeExecutor: ConvexTradeExecutor;
let harvester: Harvester;
let vault: Vault;
let baseRewardPool: IConvexRewards;

let USDC: IERC20;
let LP: IERC20;
let CRV: IERC20;
let CVX: IERC20;
let _3CRV: IERC20;

let keeperAddress: string,
  governanceAddress: string,
  signer: SignerWithAddress,
  invalidSigner: SignerWithAddress;

const deploy = async () => {
  LP = (await ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    ConvexTradeExecutorConfig.ust3Pool
  )) as IERC20;
  CRV = (await ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    CRV_ADDR
  )) as IERC20;
  CVX = (await ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    CVX_ADDR
  )) as IERC20;
  _3CRV = (await ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    _3CRV_ADDR
  )) as IERC20;

  baseRewardPool = (await ethers.getContractAt(
    "IConvexRewards",
    ConvexTradeExecutorConfig.baseRewardPool
  )) as IConvexRewards;

  USDC = await getUSDCContract();

  vault = (await ethers.getContractAt(
    "Vault",
    DeployedAddresses.vault
  )) as Vault;

  harvester = (await ethers.getContractAt(
    "Harvester",
    DeployedAddresses.harvester
  )) as Harvester;

  convexTradeExecutor = (await ethers.getContractAt(
    "ConvexTradeExecutor",
    DeployedAddresses.convexTradeExec
  )) as ConvexTradeExecutor;
};

describe("[MAINNET] Convex Trade Executor", function () {
  before(async () => {
    keeperAddress = "0xAE75B29ADe678372D77A8B41225654138a7E6ff1";
    governanceAddress = "0x6b29610D6c6a9E47812bE40F1335918bd63321bf";
    signer = (await ethers.getSigners())[0];
    invalidSigner = (await ethers.getSigners())[1];

    await deploy();
    await vault.addExecutor(DeployedAddresses.convexTradeExec);
  });

  it("Should deploy Harvester correctly", async () => {
    expect(await harvester.governance()).equals(governanceAddress);
    expect(await harvester.wantToken()).equals(HarvesterConfig.wantToken);
  });

  it("Should deploy ConvexTradeExecutor correctly", async () => {
    expect(await convexTradeExecutor.harvester()).equals(harvester.address);
    expect(await convexTradeExecutor.governance()).equals(governanceAddress);

    expect(await convexTradeExecutor.wantToken()).equals(wantTokenL1);
    expect(await convexTradeExecutor.lpToken()).equals(
      ConvexTradeExecutorConfig.ust3Pool
    );

    expect(await convexTradeExecutor.baseRewardPool()).equals(
      ConvexTradeExecutorConfig.baseRewardPool
    );
    expect(await convexTradeExecutor.ust3Pool()).equals(
      ConvexTradeExecutorConfig.ust3Pool
    );
    expect(await convexTradeExecutor.curve3PoolZap()).equals(
      ConvexTradeExecutorConfig.curve3PoolZap
    );
  });

  it("Should deposit correctly", async () => {
    const usdcBal = await USDC.balanceOf(vault.address);
    await vault.depositIntoExecutor(
      DeployedAddresses.convexTradeExec,
      usdcBal,
      {
        gasLimit: 5e6
      }
    );

    const paramsInBytes = ethers.utils.AbiCoder.prototype.encode(
      ["tuple(uint256)"],
      [[usdcBal]]
    );

    expect(await USDC.balanceOf(convexTradeExecutor.address)).equals(usdcBal);
    expect(await LP.balanceOf(convexTradeExecutor.address)).equals(0);

    await convexTradeExecutor.connect(signer).initiateDeposit(paramsInBytes, {
      gasLimit: 5e6
    });

    console.log(
      "LP after deposit:",
      (await LP.balanceOf(convexTradeExecutor.address)).toString()
    );

    expect((await LP.balanceOf(convexTradeExecutor.address)).gt(0));
  });

  it("Should open position correctly", async () => {
    const convexLpBal = await LP.balanceOf(convexTradeExecutor.address);
    const paramsInBytes = ethers.utils.AbiCoder.prototype.encode(
      ["tuple(uint256)"],
      [[convexLpBal]]
    );

    expect(await baseRewardPool.balanceOf(convexTradeExecutor.address)).equals(
      0
    );

    await convexTradeExecutor.connect(signer).openPosition(paramsInBytes, {
      gasLimit: 5e6
    });
    const convexStakedBal = await baseRewardPool.balanceOf(
      convexTradeExecutor.address
    );
    console.log("Convex staked bal:", convexStakedBal.toString());

    expect(convexStakedBal).equals(convexLpBal);
  });

  it("Should setup harvester correctly and initialize on handler", async () => {
    await harvester.connect(signer).approve({
      gasLimit: 5e6
    });
    expect((await CRV.allowance(harvester.address, CRVETH)).toString()).equals(
      MAX_INT
    );
    expect((await CVX.allowance(harvester.address, CVXETH)).toString()).equals(
      MAX_INT
    );
    expect(
      (await _3CRV.allowance(harvester.address, _3CRVPOOL)).toString()
    ).equals(MAX_INT);
  });

  it("Should get rewards correctly and harvest to USDC", async () => {
    let beforeReward = await baseRewardPool.earned(convexTradeExecutor.address);
    await mineBlocks(1);
    let afterReard = await baseRewardPool.earned(convexTradeExecutor.address);
    console.log("Before reward:", beforeReward.toString());
    console.log("After reward:", afterReard.toString());
    const initialUSDC = await USDC.balanceOf(convexTradeExecutor.address);
    await convexTradeExecutor.connect(signer).claimRewards("0x00", {
      gasLimit: 5e6
    });

    const finalUSDC = await USDC.balanceOf(convexTradeExecutor.address);
    const paramsInBytes = ethers.utils.AbiCoder.prototype.encode(
      ["tuple(uint256)"],
      [[finalUSDC]]
    );

    await convexTradeExecutor.connect(signer).initiateDeposit(paramsInBytes, {
      gasLimit: 5e6
    });
    console.log("USDC rewards obtained:", finalUSDC.toString());

    expect(finalUSDC.gt(initialUSDC));
  });

  it("Should close position correctly", async () => {
    const initialLpBal = await LP.balanceOf(convexTradeExecutor.address);

    const paramsInBytes = ethers.utils.AbiCoder.prototype.encode(
      ["tuple(uint256)"],
      [[(await baseRewardPool.balanceOf(convexTradeExecutor.address)).div(2)]]
    );

    await convexTradeExecutor.connect(signer).closePosition(paramsInBytes, {
      gasLimit: 5e6
    });

    const finalLpBal = await LP.balanceOf(convexTradeExecutor.address);
    console.log("Lp after close:", finalLpBal.toString());

    expect(finalLpBal.gt(initialLpBal));
  });

  it("Should withdraw correctly", async () => {
    const totalFund = (await convexTradeExecutor.positionInWantToken())[0];
    console.log("Position in want:", totalFund.toString());

    const initialUsdcBal = await USDC.balanceOf(convexTradeExecutor.address);
    const paramsInBytes = ethers.utils.AbiCoder.prototype.encode(
      ["tuple(uint256)"],
      [[totalFund]]
    );

    await convexTradeExecutor.initateWithdraw(paramsInBytes, {
      gasLimit: 5e6
    });

    const finalUsdcBal = await USDC.balanceOf(convexTradeExecutor.address);

    console.log(
      "Final fund:",
      (await convexTradeExecutor.positionInWantToken())[0].toString()
    );

    expect(finalUsdcBal.gt(initialUsdcBal));

    await vault.withdrawFromExecutor(
      DeployedAddresses.convexTradeExec,
      finalUsdcBal,
      {
        gasLimit: 5e6
      }
    );

    expect(await USDC.balanceOf(vault.address)).equals(finalUsdcBal);
  });
});
