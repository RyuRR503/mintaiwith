// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {VaultDataSchema, FieldDescriptor, FactoryPolicy} from "flap/IVaultSchemasV1.sol";
import {DirectLaunchAccess, IDirectLaunchVaultFactory} from "./flap/DirectLaunchBases.sol";
import {
    FeeSlotType,
    FeeConfig,
    FeeConfigVault,
    CreateTaxTokenParams,
    DistributionTarget,
    Distribution
} from "./flap/IDirectPoolLaunch.sol";
import {MintAIParams as P} from "./MintAIParams.sol";
import {IAntiScam, IMintAICards, IMintAIDuel, IMintAILauncherFactory, IMintAIUpgrades} from "./MintAIInterfaces.sol";
import {MintAIVault} from "./MintAIVault.sol";

/**
 * @title MintAIVaultFactory
 * @notice Pool Launch vault factory. Spec version is `pl-v1`.
 *         The cards contract is created earlier by {MintAILauncherFactory}. This factory only
 *         creates the vault inside the launch, and only for that cards contract.
 *         The 0.5x floor is not returned from here. Flap writes 5000 onto the Portal when it
 *         enables this factory. A launch that also has a launcher uses this factory's multiplier.
 *         This factory, the duel, and the market logic each sit behind a beacon. The Guardian upgrades them
 *         through {MintAIUpgradeAdmin}. New storage goes at the end.
 */
contract MintAIVaultFactory is Initializable, DirectLaunchAccess, IDirectLaunchVaultFactory {
    /// @notice The multiplier Flap must set on the Portal for this factory. The Portal does not read it.
    uint16 public constant FLOOR_MULTIPLIER_BPS = 5_000;

    address public upgrades;
    address public selfBeacon;
    address public vaultBeacon;
    address public deployer;
    address public duel;
    address public duelBeacon;
    /// @notice Beacon of the market logic the cards proxy delegatecalls.
    address public marketBeacon;

    address public launcherFactory;
    address public cards;
    mapping(address => address) public vaultOf;
    address public launchedToken;

    address[] private _presaleBuyers;
    mapping(address => bool) private _presaleSeen;

    event LauncherAttached(address indexed launcherFactory);
    event CardsRegistered(address indexed cards);
    event VaultCreated(address indexed vault, address indexed token, address indexed cards);
    event VaultImplementationUpgraded(address indexed previous, address indexed next);

    error UnsupportedLaunchKind(uint8 kind);
    error BadCreator(address creator);
    error NotLaunching();
    error AlreadyLaunched();
    error BadLaunch(string reason);
    error ZeroAddress();
    error AlreadyCreated();
    error NotDeployer();
    error NotLauncher();
    error NotCards();
    error ScamName();
    error UnsupportedChain();
    error AlreadyBootstrapped();

    /// @notice Anti-scam module Flap deploys on BSC mainnet. It exposes `isScamWord(name, symbol)`.
    address public constant ANTI_SCAM_MAINNET = 0xfFb69d59f62454f3B8322Bc1a9FCE6E171a5264f;
    /// @notice Anti-scam module Flap deploys on BSC testnet.
    address public constant ANTI_SCAM_TESTNET = 0x5CfbE713d070e87F67D1bc84312B7eB8Fe4F2B5E;

    bytes32 private constant CREATOR_EXTENSION_ID = keccak256("flap.extension.creator.v1");

    bool private bootstrapped;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Called on the implementation by the system deployer. Deploys this factory's beacon and proxy.
    function bootstrap(address upgradeAdmin_, address deployer_) external returns (address proxy) {
        _guardBootstrap();
        if (upgradeAdmin_ == address(0) || deployer_ == address(0)) revert ZeroAddress();
        address beacon = address(new UpgradeableBeacon(address(this), upgradeAdmin_));
        proxy = address(new BeaconProxy(beacon, abi.encodeCall(this.initialize, (upgradeAdmin_, deployer_, beacon))));
    }

    /// @notice Proxy constructor. The system deployer passes the child beacons afterwards through {configure}.
    function initialize(address upgradeAdmin_, address deployer_, address selfBeacon_) external initializer {
        if (upgradeAdmin_ == address(0) || deployer_ == address(0) || selfBeacon_ == address(0)) revert ZeroAddress();
        upgrades = upgradeAdmin_;
        selfBeacon = selfBeacon_;
        deployer = deployer_;
    }

    /// @notice Once, from the system deployer, after the vault, duel, and market beacons exist.
    function configure(address vaultBeacon_, address duel_, address duelBeacon_, address marketBeacon_) external {
        if (msg.sender != deployer) revert NotDeployer();
        if (vaultBeacon != address(0)) revert AlreadyCreated();
        if (vaultBeacon_ == address(0) || duel_ == address(0) || duelBeacon_ == address(0) || marketBeacon_ == address(0)) {
            revert ZeroAddress();
        }
        vaultBeacon = vaultBeacon_;
        duel = duel_;
        duelBeacon = duelBeacon_;
        marketBeacon = marketBeacon_;
    }

    /// @notice Current market implementation. Cards delegatecall this, so a beacon upgrade applies on the next call.
    function marketLogic() public view returns (address) {
        return UpgradeableBeacon(marketBeacon).implementation();
    }

    function _guardBootstrap() private {
        bytes32 slot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        address current;
        assembly {
            current := sload(slot)
        }
        if (current != address(0) || bootstrapped) revert AlreadyBootstrapped();
        bootstrapped = true;
    }

    /// @notice Once, from the system deployer, before any launcher can be created.
    function attachLauncher(address launcher) external {
        if (msg.sender != deployer) revert NotDeployer();
        if (launcher == address(0)) revert ZeroAddress();
        if (launcherFactory != address(0)) revert AlreadyCreated();
        launcherFactory = launcher;
        emit LauncherAttached(launcher);
    }

    /// @notice The launcher factory calls this in the same transaction that creates the cards.
    function registerCards(address cards_) external {
        if (msg.sender != launcherFactory || launcherFactory == address(0)) revert NotLauncher();
        if (cards != address(0)) revert AlreadyCreated();
        if (cards_ == address(0)) revert ZeroAddress();
        cards = cards_;
        emit CardsRegistered(cards_);
    }

    /// @notice The anti-scam module for this chain. Mainnet and testnet only.
    function antiScamModule() public view returns (address) {
        uint256 id = block.chainid;
        if (id == 56) return ANTI_SCAM_MAINNET;
        if (id == 97) return ANTI_SCAM_TESTNET;
        revert UnsupportedChain();
    }

    /// @notice Revert when `name` or `symbol` is on this chain's anti-scam list.
    function rejectScam(string calldata name, string calldata symbol) external view {
        _rejectScam(name, symbol);
    }

    /// @notice Cards call this while building the launch. It rejects a scam name or symbol and returns the
    ///         extension that shows the wallet from `Portal.newLauncher`, not this contract.
    function creatorExtension() external view returns (bytes32 extensionID, bytes32 creatorWord) {
        if (msg.sender != cards) revert NotCards();
        _rejectScam(IMintAICards(cards).tokenName(), IMintAICards(cards).tokenSymbol());
        address creator = IMintAILauncherFactory(launcherFactory).launchCreator();
        if (creator == address(0)) revert ZeroAddress();
        return (CREATOR_EXTENSION_ID, bytes32(uint256(uint160(creator))));
    }

    function _rejectScam(string memory name, string memory symbol) internal view {
        (bool nameScam, bool symbolScam) = IAntiScam(antiScamModule()).isScamWord(name, symbol);
        if (nameScam || symbolScam) revert ScamName();
    }

    /// @notice Cards call this on the first presale purchase of an address, in purchase order.
    function notePresaleBuyer(address buyer) external {
        if (msg.sender != cards) revert NotCards();
        if (buyer == address(0) || _presaleSeen[buyer]) return;
        _presaleSeen[buyer] = true;
        _presaleBuyers.push(buyer);
    }

    function presaleBuyerCount() external view returns (uint256) {
        return _presaleBuyers.length;
    }

    function presaleBuyer(uint256 index) external view returns (address) {
        return _presaleBuyers[index];
    }

    function newVault(address token, address creator, uint8 launchKind, bytes calldata launchParams)
        external
        override
        onlyHub
        returns (address vault)
    {
        if (launchKind != 0) revert UnsupportedLaunchKind(launchKind);
        if (cards == address(0) || creator != cards) revert BadCreator(creator);
        if (!IMintAICards(cards).launching()) revert NotLaunching();
        if (launchedToken != address(0)) revert AlreadyLaunched();
        (CreateTaxTokenParams memory p, Distribution memory d) =
            abi.decode(launchParams, (CreateTaxTokenParams, Distribution));
        _validate(p, d);

        vault = address(
            new BeaconProxy{salt: bytes32(uint256(uint160(token)))}(
                vaultBeacon, abi.encodeCall(MintAIVault.initialize, (token, cards, duel))
            )
        );
        IMintAIDuel(duel).bindVault(vault);
        vaultOf[token] = vault;
        launchedToken = token;
        emit VaultCreated(vault, token, cards);
    }

    function upgradeVaultImplementation(address newImplementation) external override onlyGuardian {
        address prev = UpgradeableBeacon(vaultBeacon).implementation();
        IMintAIUpgrades(upgrades).upgrade(vaultBeacon, newImplementation);
        emit VaultImplementationUpgraded(prev, newImplementation);
    }

    function isQuoteTokenSupported(address quoteToken) public pure override returns (bool) {
        return quoteToken == address(0);
    }

    function factorySpecVersion() public pure override returns (string memory) {
        return "pl-v1";
    }

    function vaultDataSchema() public pure override returns (VaultDataSchema memory schema) {
        schema.description = "MINT.AI card vault. Only the cards contract created by the paired launcher factory "
            "can launch. vaultData must be empty. 777,777,777 supply, 124,672,000 tokens + 36.75 BNB in the pool, "
            "2% buy and sell tax, VAULT slot 100%, remainder to the vault. Tax revenue: 50% card holders, 30% card "
            "floor fund (buys the cheapest listed cards and burns them), 20% ops.";
        schema.fields = new FieldDescriptor[](0);
        schema.isArray = false;
    }

    function tokenCreationPolicies() public pure override returns (FactoryPolicy[] memory policies) {
        policies = new FactoryPolicy[](6);
        policies[0] = FactoryPolicy("creator", "eq", "", "Only the cards contract created by the paired launcher");
        policies[1] = FactoryPolicy("totalSupply", "eq", abi.encode(P.TOTAL_SUPPLY), "777,777,777 tokens");
        policies[2] = FactoryPolicy("poolToken", "eq", abi.encode(P.POOL_TOKEN), "124,672,000 tokens in the pool");
        policies[3] = FactoryPolicy("poolQuote", "eq", abi.encode(P.POOL_QUOTE), "36.75 BNB, native quote only");
        policies[4] = FactoryPolicy("buyTaxRate", "eq", abi.encode(uint256(P.TAX_BPS)), "2% buy and sell tax");
        policies[5] = FactoryPolicy("feeConfigs", "eq", "", "Single VAULT slot of 10000 bps pointing to this factory");
    }

    function _validate(CreateTaxTokenParams memory p, Distribution memory d) private view {
        if (p.quoteToken != address(0)) revert BadLaunch("quote");
        if (p.totalSupply != P.TOTAL_SUPPLY) revert BadLaunch("supply");
        if (p.poolToken != P.POOL_TOKEN || p.poolQuote != P.POOL_QUOTE) revert BadLaunch("pool");
        if (p.buyTaxRate != P.TAX_BPS || p.sellTaxRate != P.TAX_BPS) revert BadLaunch("tax");
        if (p.taxDuration != P.TAX_DURATION) revert BadLaunch("taxDuration");
        if (p.creatorBuyQuote != 0) revert BadLaunch("creatorBuy");
        if (p.commissionReceiver != address(0)) revert BadLaunch("commission");
        if (p.feeConfigs.length != 1) revert BadLaunch("slots");
        FeeConfig memory f = p.feeConfigs[0];
        if (f.feeType != FeeSlotType.VAULT || f.bps != 10_000) revert BadLaunch("vault slot");
        FeeConfigVault memory v = abi.decode(f.configData, (FeeConfigVault));
        if (v.vaultFactory != address(this) || v.vaultData.length != 0) revert BadLaunch("vault data");
        if (d.target != DistributionTarget.VAULT || d.amount != P.RESERVE) revert BadLaunch("distribution");
    }
}
