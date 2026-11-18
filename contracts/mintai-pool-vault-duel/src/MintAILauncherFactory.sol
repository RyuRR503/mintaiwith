// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MintAICardsLens} from "./MintAICardsLens.sol";
import {FieldDescriptor} from "flap/IVaultSchemasV1.sol";
import {DirectLaunchAccess} from "./flap/DirectLaunchBases.sol";
import {MintAICards} from "./MintAICards.sol";
import {MintAIVaultFactory} from "./MintAIVaultFactory.sol";
import {MintAIDuel} from "./MintAIDuel.sol";
import {MintAIUpgradeAdmin} from "./MintAIUpgradeAdmin.sol";
import {IMintAIDuel, IMintAIUpgrades} from "./MintAIInterfaces.sol";

/// @notice Form schema for `Portal.newLauncher` data. Same field order as `VaultDataSchema`.
struct LauncherDataSchema {
    string description;
    FieldDescriptor[] fields;
    bool isArray;
}

/**
 * @title MintAILauncherFactory
 * @notice Pool Launch launcher factory. Spec version is `lf-v1`.
 *         Portal calls `newLauncher` once. That creates the cards contract, which runs the presale
 *         and later calls `launchTaxTokenV2` itself. The floor multiplier is not returned here.
 *         This factory sits behind a beacon. The Guardian upgrades it through {MintAIUpgradeAdmin}.
 *         New storage goes at the end.
 */
contract MintAILauncherFactory is Initializable, DirectLaunchAccess {
    address public upgrades;
    address public selfBeacon;
    address public cardsBeacon;
    address public vaultFactory;
    bytes32 public configHash;

    address public cards;
    address public launchCreator;

    bool private bootstrapped;

    event LauncherCreated(address indexed cards, address indexed creator);
    event CardsImplementationUpgraded(address indexed previous, address indexed next);

    error ZeroAddress();
    error AlreadyCreated();
    error BadConfig();
    error NotOwner();
    error AlreadyBootstrapped();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Called on the implementation by the system deployer. Deploys this factory's beacon and proxy.
    function bootstrap(
        address upgradeAdmin_,
        address cardsImpl,
        bytes32 configHash_,
        address vaultFactory_
    ) external returns (address proxy) {
        bytes32 slot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        address current;
        assembly {
            current := sload(slot)
        }
        if (current != address(0) || bootstrapped) revert AlreadyBootstrapped();
        bootstrapped = true;
        if (upgradeAdmin_ == address(0) || cardsImpl == address(0) || configHash_ == bytes32(0) || vaultFactory_ == address(0)) {
            revert ZeroAddress();
        }
        address beacon = address(new UpgradeableBeacon(address(this), upgradeAdmin_));
        proxy = address(
            new BeaconProxy(
                beacon, abi.encodeCall(this.initialize, (upgradeAdmin_, cardsImpl, configHash_, vaultFactory_, beacon))
            )
        );
    }

    function initialize(
        address upgradeAdmin_,
        address cardsImpl,
        bytes32 configHash_,
        address vaultFactory_,
        address selfBeacon_
    ) external initializer {
        if (
            upgradeAdmin_ == address(0) || cardsImpl == address(0) || configHash_ == bytes32(0) || vaultFactory_ == address(0)
                || selfBeacon_ == address(0)
        ) revert ZeroAddress();
        upgrades = upgradeAdmin_;
        selfBeacon = selfBeacon_;
        cardsBeacon = address(new UpgradeableBeacon(cardsImpl, upgradeAdmin_));
        configHash = configHash_;
        vaultFactory = vaultFactory_;
    }

    function factorySpecVersion() external pure returns (string memory) {
        return "lf-v1";
    }

    /// @notice Portal-only. `creator` is the wallet that called `Portal.newLauncher`, and it must be `init.owner`.
    ///         `msg.value` is the Portal salt-lock fee. It is forwarded into the new cards contract, which locks
    ///         the init salt before this call returns.
    function newLauncher(address creator, bytes calldata data) external payable onlyHub returns (address launcher) {
        if (creator == address(0)) revert ZeroAddress();
        if (cards != address(0)) revert AlreadyCreated();
        MintAICards.InitParams memory init = abi.decode(data, (MintAICards.InitParams));
        if (keccak256(abi.encode(init)) != configHash) revert BadConfig();
        if (creator != init.owner) revert NotOwner();
        launcher = address(
            new BeaconProxy{value: msg.value}(cardsBeacon, abi.encodeCall(MintAICards.initialize, (init, vaultFactory)))
        );
        cards = launcher;
        launchCreator = creator;
        MintAIVaultFactory(vaultFactory).registerCards(launcher);
        IMintAIDuel(MintAIVaultFactory(vaultFactory).duel()).bindCards(launcher);
        emit LauncherCreated(launcher, creator);
    }

    function launcherDataSchema() external pure returns (LauncherDataSchema memory schema) {
        schema.description = "MINT.AI presale launcher. data is abi.encode of the InitParams fixed at deployment. "
            "One launcher, one launch. The cards contract locks its own salt and calls launchTaxTokenV2.";
        schema.fields = new FieldDescriptor[](8);
        schema.fields[0] = FieldDescriptor("owner", "address", "Project owner", 0);
        schema.fields[1] = FieldDescriptor("opsWallet", "address", "Ops wallet", 0);
        schema.fields[2] = FieldDescriptor("teamWallet", "address", "Team wallet", 0);
        schema.fields[3] = FieldDescriptor("router", "address", "Pancake V2 router for this chain", 0);
        schema.fields[4] = FieldDescriptor("tokenName", "string", "Token name", 0);
        schema.fields[5] = FieldDescriptor("tokenSymbol", "string", "Token symbol", 0);
        schema.fields[6] = FieldDescriptor("tokenMeta", "string", "Token metadata", 0);
        schema.fields[7] = FieldDescriptor(
            "salt", "bytes32", "CREATE2 salt, locked in this transaction. The token address must end in 7777", 0
        );
        schema.isArray = false;
    }

    /// @notice Guardian upgrades the cards beacon. The spec name is `upgradeVaultImplementation`.
    function upgradeVaultImplementation(address newImplementation) external onlyGuardian {
        address prev = UpgradeableBeacon(cardsBeacon).implementation();
        IMintAIUpgrades(upgrades).upgrade(cardsBeacon, newImplementation);
        emit CardsImplementationUpgraded(prev, newImplementation);
    }
}

/// @notice Deploys both factory proxies, the duel proxy, the market beacon, the order-book lens, and the upgrade admin in one transaction.
///         The market implementation is deployed first and passed in, the same way as the vault and cards implementations.
///         Cards are not created here. `configHash` is `keccak256(abi.encode(init))`. After Flap enables both
///         factories, call `Portal.newLauncher(launcherFactory, abi.encode(init))` with that same init and the
///         salt-lock fee. Set the vault factory multiplier to 5000. That is the multiplier a paired launch uses.
///         The addresses below are the proxies. The Guardian upgrades through {upgrades}.
///         {lens} is the read-only order book. It holds no funds. Pass a cards address to page its listings.
contract MintAISystemDeployer {
    MintAIVaultFactory public immutable vaultFactory;
    MintAILauncherFactory public immutable launcherFactory;
    MintAIDuel public immutable duel;
    MintAIUpgradeAdmin public immutable upgrades;
    MintAICardsLens public immutable lens;

    error EmptyMarket();

    constructor(address vaultImpl, address cardsImpl, address marketImpl, bytes32 configHash) {
        if (marketImpl.code.length == 0) revert EmptyMarket();
        upgrades = new MintAIUpgradeAdmin();
        MintAIVaultFactory vaultImplFactory = new MintAIVaultFactory();
        vaultFactory = MintAIVaultFactory(vaultImplFactory.bootstrap(address(upgrades), address(this)));
        address duelImpl = address(new MintAIDuel());
        address duelBeacon_ = address(new UpgradeableBeacon(duelImpl, address(upgrades)));
        address duelProxy =
            address(new BeaconProxy(duelBeacon_, abi.encodeCall(MintAIDuel.initialize, (address(vaultFactory)))));
        address marketBeacon_ = address(new UpgradeableBeacon(marketImpl, address(upgrades)));
        address vaultBeacon_ = address(new UpgradeableBeacon(vaultImpl, address(upgrades)));
        vaultFactory.configure(vaultBeacon_, duelProxy, duelBeacon_, marketBeacon_);
        MintAILauncherFactory launcherImpl = new MintAILauncherFactory();
        launcherFactory = MintAILauncherFactory(
            launcherImpl.bootstrap(address(upgrades), cardsImpl, configHash, address(vaultFactory))
        );
        vaultFactory.attachLauncher(address(launcherFactory));
        upgrades.addOperator(address(vaultFactory));
        upgrades.addOperator(address(launcherFactory));
        upgrades.addBeacon(vaultFactory.selfBeacon());
        upgrades.addBeacon(vaultFactory.vaultBeacon());
        upgrades.addBeacon(vaultFactory.duelBeacon());
        upgrades.addBeacon(vaultFactory.marketBeacon());
        upgrades.addBeacon(launcherFactory.selfBeacon());
        upgrades.addBeacon(launcherFactory.cardsBeacon());
        upgrades.finish();
        duel = MintAIDuel(payable(vaultFactory.duel()));
        lens = new MintAICardsLens();
    }
}
