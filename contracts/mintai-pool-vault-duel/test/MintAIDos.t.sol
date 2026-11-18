// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MintAIBase} from "./MintAIBase.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAICardMarket} from "../src/MintAICardMarket.sol";
import {MintAICardsBase} from "../src/MintAICardsBase.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAIVaultFactory} from "../src/MintAIVaultFactory.sol";
import {MintAILauncherFactory, MintAISystemDeployer} from "../src/MintAILauncherFactory.sol";
import {GasBombReceiver, ReturnBombReceiver, ReentrantReceiver, RevertingReceiver} from "./MintAIMocks.sol";

contract MintAIDosTest is MintAIBase {
    function setUp() public {
        _setUpLocal();
    }

    function test_launcherDescriptionIsTheFeedJson() public {
        string memory plain = cards.description();
        assertLt(bytes(plain).length, 4096);
        assertEq(plain, _feedJson("MINT.AI", "MINT.AI"));

        MintAICards.InitParams memory init = MintAICards.InitParams({
            owner: address(this),
            opsWallet: ops,
            teamWallet: team,
            router: address(router),
            tokenName: 'A"B\\C',
            tokenSymbol: "MINT.AI",
            tokenMeta: "",
            salt: bytes32(uint256(2))
        });
        MintAISystemDeployer system =
            new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(abi.encode(init))
        );
        MintAILauncherFactory extra = system.launcherFactory();
        vm.prank(HUB);
        extra.newLauncher{value: 0.01 ether}(address(this), abi.encode(init));
        assertEq(MintAICards(payable(extra.cards())).description(), _feedJson('A"B\\C', "MINT.AI"));
        assertEq(new MintAIVault().vaultUISchema().methods[3].name, "claimTokens");
    }

    function _feedJson(string memory name, string memory symbol) private pure returns (string memory) {
        name = _expectEscape(name);
        return string.concat(
            '{"v":1,"name":"',
            name,
            '","symbol":"',
            symbol,
            '","quoteToken":"0x0000000000000000000000000000000000000000","targetRaise":"49000000000000000000","poolTokenRatio":"',
            vm.toString(uint256(124_672_000 ether) * 1e18 / uint256(777_777_777 ether)),
            '","titleZh":"MINT.AI","titleEn":"MINT.AI","summaryZh":"',
            "\u9884\u552e 20,000 \u5f20\uff0c\u6bcf\u5f20 0.00245 BNB\uff0c7 \u5929\u6ca1\u5356\u6ee1\u53ef\u5168\u989d\u9000\u6b3e\u3002\u5f00\u76d8\u540e\u6bcf\u5f20 0.0049 BNB\u3002\u6bcf\u7b14\u94f8\u9020\u6b3e 25% \u7ed9\u8fd0\u8425\u3002\u9884\u552e\u5361\u548c\u56e2\u961f\u5361\u5404\u5f97 8,440 \u679a\u3002\u7a0e 2%\uff0c\u6309\u6301\u5361\u4eba 50%\u3001\u5730\u677f 30%\u3001\u8fd0\u8425 20% \u5206\u914d\u3002\u5e02\u573a\u6210\u4ea4\u8d39 1%\u3002",
            '","summaryEn":"',
            "Presale: 20,000 cards at 0.00245 BNB. Unsold after 7 days can be fully refunded. After launch, 0.0049 BNB per card. 25% of each mint payment goes to operations. Each presale card and team card receives 8,440 tokens. The 2% tax splits 50% to holders, 30% to the floor, and 20% to operations. Market fee is 1%.",
            '"}'
        );
    }

    function _expectEscape(string memory s) private pure returns (string memory) {
        if (keccak256(bytes(s)) != keccak256(bytes('A"B\\C'))) return s;
        return 'A\\"B\\\\C';
    }

    function test_dos_agentIdAndCap() public {
        address a = makeAddr("a");
        vm.deal(a, 1 ether);
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.AgentIdRequired.selector);
        cards.mint{value: 0.00245 ether}(1, 0);
        _mint(a, 10);
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.MintCapReached.selector);
        cards.mint{value: 0.00245 ether}(1, 0);
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.TransferLocked.selector);
        cards.transferFrom(a, makeAddr("b"), 1);
    }

    function test_dos_refundRejectDoesNotStickAndOthersStillRefund() public {
        RevertingReceiver bad = new RevertingReceiver();
        _id(address(bad));
        vm.deal(address(bad), 1 ether);
        vm.prank(address(bad));
        cards.mint{value: 0.00245 ether}(1, 0);
        address good = makeAddr("good");
        uint256 paid = _mint(good, 1);
        vm.warp(block.timestamp + 7 days + 1);
        uint256[] memory one = new uint256[](1);
        one[0] = 1;
        vm.prank(address(bad));
        vm.expectRevert(MintAICardsBase.PayFailed.selector);
        cards.refund(one);
        assertEq(cards.ownerOf(1), address(bad), "failed refund keeps the card");
        one[0] = 2;
        uint256 before = good.balance;
        vm.prank(good);
        cards.refund(one);
        assertEq(good.balance - before, paid);
        _assertCardsBook();
    }

    function test_dos_guardianCannotTakeEscrow() public {
        _mint(makeAddr("a"), 3);
        uint256 escrow = address(cards).balance;
        vm.prank(_guardian());
        vm.expectRevert(abi.encodeWithSelector(MintAICardsBase.OccupiedFunds.selector, 0, escrow));
        cards.emergencyWithdrawNative(_guardian(), escrow);
        vm.deal(address(cards), escrow + 0.4 ether);
        vm.prank(_guardian());
        cards.emergencyWithdrawNative(_guardian(), 0.4 ether);
        assertEq(address(cards).balance, escrow);
        _assertCardsBook();
    }

    function test_dos_launcherIsOnceAndFactoriesStayImmutable() public {
        assertEq(cards.factory(), address(factory));
        assertEq(factory.FLOOR_MULTIPLIER_BPS(), 5_000);
        bytes32 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        assertEq(vm.load(address(factory), implSlot), bytes32(0), "vault factory is not a proxy");
        assertEq(vm.load(address(launcher), implSlot), bytes32(0), "launcher factory is not a proxy");
        assertEq(launcher.factorySpecVersion(), "lf-v1");
        assertEq(factory.factorySpecVersion(), "pl-v1");

        address stranger = makeAddr("stranger");
        vm.expectRevert(abi.encodeWithSignature("NotHub(address)", stranger));
        vm.prank(stranger);
        launcher.newLauncher(stranger, abi.encode(_init()));
        vm.expectRevert(MintAILauncherFactory.AlreadyCreated.selector);
        vm.prank(HUB);
        launcher.newLauncher(stranger, abi.encode(_init()));

        MintAICards.InitParams memory init = _init();
        MintAISystemDeployer extra =
            new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(abi.encode(init))
        );
        MintAICards.InitParams memory wrong = _init();
        wrong.salt = bytes32(uint256(99));
        MintAILauncherFactory extraLauncher = extra.launcherFactory();
        vm.expectRevert(MintAILauncherFactory.BadConfig.selector);
        vm.prank(HUB);
        extraLauncher.newLauncher(stranger, abi.encode(wrong));
        vm.expectRevert(MintAILauncherFactory.NotOwner.selector);
        vm.prank(HUB);
        extraLauncher.newLauncher(stranger, abi.encode(init));
        vm.expectRevert(abi.encodeWithSelector(MintAICardsBase.WrongPayment.selector, 0.01 ether, 0));
        vm.prank(HUB);
        extraLauncher.newLauncher(address(this), abi.encode(init));
        vm.deal(HUB, 1 ether);
        vm.prank(HUB);
        extraLauncher.newLauncher{value: 0.01 ether}(address(this), abi.encode(init));
        assertEq(extraLauncher.launchCreator(), address(this));

        vm.expectRevert(MintAIVaultFactory.NotCards.selector);
        vm.prank(stranger);
        factory.notePresaleBuyer(stranger);
        assertTrue(address(extra.launcherFactory()) != address(extra.vaultFactory()));
        assertEq(extra.vaultFactory().launcherFactory(), address(extra.launcherFactory()));

        address nextCards = address(new MintAICards());
        vm.expectRevert();
        vm.prank(stranger);
        launcher.upgradeVaultImplementation(nextCards);
        vm.prank(_guardian());
        launcher.upgradeVaultImplementation(nextCards);
        assertEq(cards.name(), "MINT.AI", "the cards proxy keeps its name");
    }

    function _init() internal view returns (MintAICards.InitParams memory) {
        return MintAICards.InitParams({
            owner: address(this),
            opsWallet: ops,
            teamWallet: team,
            router: address(router),
            tokenName: "MINT.AI",
            tokenSymbol: "MINT.AI",
            tokenMeta: "",
            salt: bytes32(uint256(1))
        });
    }

    function test_dos_strangerCannotAdminister() public {
        address a = makeAddr("a");
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.NotOwnerOrGuardian.selector);
        cards.setOpsWallet(a);
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.NotTeam.selector);
        cards.mintTeam(team, 1);
        address impl = address(new MintAIVault());
        vm.prank(a);
        vm.expectRevert();
        factory.upgradeVaultImplementation(impl);
        vm.prank(a);
        vm.expectRevert();
        factory.newVault(address(1), address(cards), 0, "");
    }

    function test_dos_hostileOpsDoesNotBlockLaunchOrMint() public {
        address bomb = address(new GasBombReceiver());
        cards.setOpsWallet(bomb);
        _sellOutPresale();
        _launch();
        assertEq(cards.opsOwed(), 12.25 ether, "12.25 kept when the push burns its gas");
        assertEq(bomb.balance, 0);
        address buyer = makeAddr("buyer");
        _mint(buyer, 1);
        assertGt(cards.opsOwed(), 12.25 ether, "post-open 25% also stays owed");
        _assertCardsBook();

        address cold = makeAddr("cold");
        cards.setOpsWallet(cold);
        uint256 owed = cards.opsOwed();
        cards.poke();
        assertEq(cold.balance, owed, "a normal wallet collects everything owed");
        assertEq(cards.opsOwed(), 0);
        _assertCardsBook();
    }

    function test_dos_returnBombOpsIsCapped() public {
        address bomb = address(new ReturnBombReceiver());
        cards.setOpsWallet(bomb);
        _mint(makeAddr("a"), 1);
        _sellOutPresale();
        uint256 g = gasleft();
        _launch();
        uint256 used = g - gasleft();
        assertLt(used, 30_000_000, "launch finishes");
        assertEq(cards.opsOwed(), 12.25 ether);
        assertEq(bomb.balance, 0, "return data is not copied into memory");
        _assertCardsBook();
    }

    function test_dos_reentrantClaimPaysOnce() public {
        _sellOutPresale();
        _launch();
        ReentrantReceiver r = new ReentrantReceiver();
        r.setCards(address(cards));
        address holder = cards.ownerOf(1);
        vm.prank(holder);
        cards.transferFrom(holder, address(r), 1);
        vm.deal(address(vault), 1 ether);
        vault.sync();
        uint256 dividend = cards.pendingDividendOf(1);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        vm.prank(address(r));
        cards.claim(ids);
        assertEq(r.successes(), 0, "reentering claim and poke is rejected");
        assertEq(address(r).balance, dividend, "paid once");
        assertEq(cards.pendingDividendOf(1), 0);
        _assertCardsBook();
    }

    function test_dos_hostileSellerCannotBlockTheFloorSweep() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address gas = address(new GasBombReceiver());
        address ret = address(new ReturnBombReceiver());
        address a = cards.ownerOf(1);
        vm.startPrank(a);
        cards.transferFrom(a, gas, 1);
        cards.transferFrom(a, ret, 2);
        vm.stopPrank();
        _list(1, 0.002 ether);
        _list(2, 0.002 ether);
        _list(3, 0.002 ether);
        uint256 used = _fire();
        assertEq(vault.totalFloorBurned(), 3, "the trigger run is not blocked by hostile sellers");
        assertLt(used, 1_000_000, "bounded gas");
        assertEq(cards.proceedsOwed(gas), 0.002 ether, "gas bomb is credited");
        assertEq(cards.proceedsOwed(ret), 0.002 ether, "return bomb is credited");
        _assertCardsBook();
    }

    function test_dos_strangerCannotFundOrDrainTheFloor() public {
        _sellOutPresale();
        _launch();
        vm.expectRevert(MintAICardsBase.NotVault.selector);
        cards.onVaultRevenue{value: 0}(0, 0, 0);
        _list(1, 0.002 ether);
        vm.deal(address(this), 1 ether);
        vm.expectRevert(MintAICardsBase.NotVault.selector);
        cards.floorBuy{value: 0.002 ether}(1);
        vm.expectRevert(MintAIVault.NotTrigger.selector);
        vault.trigger(1);
        vm.deal(address(vault), 1 ether);
        vault.sync();
        assertEq(
            vault.floorFund() + vault.triggerReserve() + vault.duelBudget(),
            address(vault).balance,
            "the fund stays in the vault"
        );
        assertEq(vault.unrecognizedTax(), 0);
        vm.prank(address(vault));
        vm.expectRevert(MintAICardsBase.BadPrice.selector);
        cards.floorBuy{value: 0.001 ether}(1);
        vm.prank(address(vault));
        vm.expectRevert(MintAICardsBase.BadPrice.selector);
        cards.floorBuy{value: 0.002 ether}(2);
    }

    function test_dos_strangerCannotUseVaultHooks() public {
        _sellOutPresale();
        _launch();
        vm.expectRevert(MintAIVault.NotCards.selector);
        vault.addTeamGrants(address(this), 0, 1);
        vm.deal(address(this), 1 ether);
        vm.expectRevert(MintAIVault.NotCards.selector);
        vault.buyForMint{value: 0.1 ether}(address(this), 1, 1, 0);
        vm.expectRevert(MintAIVault.NotCards.selector);
        vault.onLaunched(address(1), address(2), address(3));
    }

    function test_dos_tokenClaimPaysOnce() public {
        _sellOutPresale();
        _launch();
        address a = address(uint160(0xA000));
        vm.warp(block.timestamp + 5 days);
        vm.prank(a);
        vault.claimTokens(0, 0);
        vm.prank(a);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        assertEq(vault.bucketReleased(0), 84_400 ether);
    }

    function test_dos_bidCancelAndDustDoNotLeak() public {
        _sellOutPresale();
        _launch();
        address a = cards.ownerOf(1);
        vm.deal(a, 1 ether);
        vm.prank(a);
        uint256 bidId = cards.placeBid{value: 0.5 ether}(0.1 ether, 5);
        assertEq(cards.bidEscrow(), 0.5 ether);
        uint256[] memory ids = new uint256[](1);
        ids[0] = bidId;
        uint256 before = a.balance;
        vm.prank(a);
        cards.cancelBids(ids);
        assertEq(a.balance - before, 0.5 ether);
        assertEq(cards.bidEscrow(), 0);
        _assertCardsBook();
    }
}
