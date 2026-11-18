// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {MintAICardMarket} from "../src/MintAICardMarket.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAILauncherFactory, MintAISystemDeployer} from "../src/MintAILauncherFactory.sol";

/// @dev The one-click deployer only. Market logic is deployed first; this transaction still creates the lens.
contract MintAISystemDeployTest is Test {
    function test_systemDeployUsesSuppliedMarketAndDeploysLens() public {
        address vaultImpl = address(new MintAIVault());
        address cardsImpl = address(new MintAICards());
        MintAICardMarket market = new MintAICardMarket();
        // address, address, address, bytes32. Constructor arguments count toward the 49,152 initcode limit.
        uint256 initcode = type(MintAISystemDeployer).creationCode.length + 128;
        assertLe(initcode, 49_152, "system initcode");

        MintAISystemDeployer system =
            new MintAISystemDeployer(vaultImpl, cardsImpl, address(market), bytes32(uint256(1)));
        assertEq(system.vaultFactory().marketLogic(), address(market), "market beacon uses the supplied implementation");
        assertEq(UpgradeableBeacon(system.vaultFactory().marketBeacon()).implementation(), address(market));
        assertGt(address(system.lens()).code.length, 0, "lens is created in the same transaction");
        assertGt(address(system.launcherFactory()).code.length, 0);
        assertGt(address(system.duel()).code.length, 0);
        assertGt(address(system.upgrades()).code.length, 0);
        assertEq(system.launcherFactory().factorySpecVersion(), "lf-v1");
        assertEq(system.vaultFactory().factorySpecVersion(), "pl-v1");
    }

    function test_systemDeployRejectsEmptyMarket() public {
        address vaultImpl = address(new MintAIVault());
        address cardsImpl = address(new MintAICards());
        vm.expectRevert(MintAISystemDeployer.EmptyMarket.selector);
        new MintAISystemDeployer(vaultImpl, cardsImpl, makeAddr("no-market"), bytes32(uint256(1)));
    }
}
