// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAICardMarket} from "../src/MintAICardMarket.sol";
import {MintAICardsBase} from "../src/MintAICardsBase.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAIVaultFactory} from "../src/MintAIVaultFactory.sol";
import {MintAILauncherFactory, MintAISystemDeployer} from "../src/MintAILauncherFactory.sol";
import {MintAIParams as P} from "../src/MintAIParams.sol";
import {IDirectLaunchPortal} from "../src/flap/IDirectPoolLaunch.sol";
import {IAntiScam, IV2Pair} from "../src/MintAIInterfaces.sol";

/// @dev One BSC mainnet fork: the mint that sells the 20,000th presale card launches by itself.
contract MintAIMainnetLaunchTest is Test {
    address internal constant HUB = 0x000042108465206185A077Edc3F3fd2b49060000;
    address internal constant TOKEN_IMPL = 0x7777c57ff7dc441c1715b2e36fa581c48B782222;
    address internal constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    bytes32 internal constant FACTORY_ADMIN_ROLE =
        0x4963b4023b6bd340aa187168ec181d3a3f0622501df2db470248e5abc5f8e0d8;

    MintAIVaultFactory internal factory;
    MintAICards internal cards;
    address internal ops = makeAddr("ops");
    address internal team = makeAddr("team");
    uint256 internal saltCursor;

    function setUp() public {
        vm.createSelectFork(_rpc());
        require(block.chainid == 56, "bsc mainnet fork required");
    }

    function test_mainnet_selloutLaunchesInsideTheMint() public {
        (factory, cards) = _deploy();
        assertTrue(cards.saltLocked(), "salt is locked at creation");
        assertFalse(cards.launched());
        (bool called,) = address(cards).call(abi.encodeWithSignature("launch()"));
        assertFalse(called, "there is no launch() to call");

        IAntiScam module = IAntiScam(factory.antiScamModule());
        assertEq(address(module), 0xfFb69d59f62454f3B8322Bc1a9FCE6E171a5264f);
        (bool nameScam, bool symbolScam) = module.isScamWord("MINT.AI", "MINT.AI");
        assertFalse(nameScam);
        assertFalse(symbolScam);

        _fill(19_990);
        assertEq(cards.paidMinted(), 19_990);
        assertFalse(cards.launched(), "still closed one batch before the cap");

        address near = makeAddr("near");
        _mint(near, 5);
        assertEq(cards.paidMinted(), 19_995);
        assertFalse(cards.launched());

        address over = makeAddr("over");
        _id(over);
        vm.deal(over, 10 * 0.00245 ether);
        vm.prank(over);
        vm.expectRevert(MintAICardsBase.PresaleFull.selector);
        cards.mint{value: 10 * 0.00245 ether}(10, 0);
        assertFalse(cards.launched(), "an overshoot does not launch");

        address closer = makeAddr("closer");
        uint256 opsBefore = ops.balance;
        _mint(closer, 5);
        assertEq(cards.paidMinted(), 20_000);
        assertTrue(cards.launched(), "the completing mint launches");
        assertEq(cards.presaleFilledAt(), block.timestamp);
        assertEq(uint16(uint160(cards.launchedToken())), 0x7777, "vanity");
        assertTrue(cards.launchedPool() != address(0));
        assertTrue(cards.vault() != address(0));
        assertEq(cards.presaleEscrow(), 0);
        assertEq(ops.balance - opsBefore, 12.25 ether, "25% of the 49 BNB presale");

        (uint112 r0, uint112 r1,) = IV2Pair(cards.launchedPool()).getReserves();
        (uint256 quote, uint256 tokens) = IV2Pair(cards.launchedPool()).token0() == cards.launchedToken()
            ? (uint256(r1), uint256(r0))
            : (uint256(r0), uint256(r1));
        assertEq(quote, P.POOL_QUOTE, "36.75 BNB in the pool");
        assertEq(tokens, P.POOL_TOKEN, "124,672,000 tokens in the pool");
        assertGt(IERC20(cards.launchedToken()).totalSupply(), 0);
    }

    function _fill(uint256 target) internal {
        uint256 batch;
        while (cards.paidMinted() < target) {
            uint256 left = target - cards.paidMinted();
            uint256 n = left < 10 ? left : 10;
            _mint(address(uint160(0xA110 + batch)), n);
            batch += 1;
        }
    }

    function _mint(address who, uint256 n) internal {
        _id(who);
        uint256 value = n * 0.00245 ether;
        vm.deal(who, value);
        vm.prank(who);
        cards.mint{value: value}(n, 0);
    }

    function _deploy() internal returns (MintAIVaultFactory f, MintAICards c) {
        MintAICards.InitParams memory init = MintAICards.InitParams({
            owner: address(this),
            opsWallet: ops,
            teamWallet: team,
            router: ROUTER,
            tokenName: "MINT.AI",
            tokenSymbol: "MINT.AI",
            tokenMeta: "",
            salt: _mineSalt()
        });
        MintAISystemDeployer deployed =
            new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(abi.encode(init))
        );
        f = deployed.vaultFactory();
        MintAILauncherFactory launcher = deployed.launcherFactory();
        vm.store(HUB, keccak256(abi.encode(address(this), FACTORY_ADMIN_ROLE)), bytes32(uint256(1)));
        ILaunchPortal(HUB).setLauncherFactoryMultiplier(address(launcher), 5_000, true);
        ILaunchPortal(HUB).setVaultFactoryMultiplier(address(f), f.FLOOR_MULTIPLIER_BPS(), true);
        uint256 saltFee = IDirectLaunchPortal(HUB).SALT_LOCK_FEE();
        vm.deal(address(this), address(this).balance + saltFee);
        address created = ILaunchPortal(HUB).newLauncher{value: saltFee}(address(launcher), abi.encode(init));
        c = MintAICards(payable(created));
    }

    function _mineSalt() internal returns (bytes32 s) {
        for (uint256 i = saltCursor + 1;; ++i) {
            s = keccak256(abi.encode("MINT.AI", i));
            address predicted = Clones.predictDeterministicAddress(TOKEN_IMPL, s, HUB);
            if (uint16(uint160(predicted)) == 0x7777 && predicted.code.length == 0) {
                saltCursor = i;
                return s;
            }
        }
    }

    function _id(address who) internal {
        vm.mockCall(AGENT_ID, abi.encodeWithSelector(bytes4(0x70a08231), who), abi.encode(uint256(1)));
    }

    function _rpc() internal view returns (string memory) {
        try vm.envString("BSC_RPC_URL") returns (string memory url) {
            if (bytes(url).length > 0) return url;
        } catch {}
        return "https://bsc.publicnode.com";
    }

    receive() external payable {}
}

interface ILaunchPortal {
    function setLauncherFactoryMultiplier(address factory, uint16 multiplierBps, bool enabled) external;
    function setVaultFactoryMultiplier(address factory, uint16 multiplierBps, bool enabled) external;
    function newLauncher(address launcherFactory, bytes calldata data) external payable returns (address launcher);
}
