// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Pool Launch types transcribed from https://docs.utter.cash/zh/docs/pool-launch.
enum FeeSlotType {
    NONE,
    DEFLATION,
    LP_BPS,
    MARKETING,
    VAULT,
    DIVIDEND
}

struct FeeConfig {
    FeeSlotType feeType;
    uint16 bps;
    bytes configData;
}

struct FeeConfigVault {
    address vaultFactory;
    bytes vaultData;
}

struct CreateTaxTokenParams {
    string name;
    string symbol;
    string meta;
    uint256 totalSupply;
    bytes32 salt;
    address quoteToken;
    uint8 dexId;
    uint256 poolQuote;
    uint256 poolToken;
    uint16 buyTaxRate;
    uint16 sellTaxRate;
    uint32 taxDuration;
    uint32 antiFarmerDuration;
    FeeConfig[] feeConfigs;
    uint8 antiSniperMode;
    uint32 exemptWindow;
    address[] exemptAddrs;
    uint256 creatorBuyQuote;
    bytes32 extensionID;
    bytes extensionData;
    address commissionReceiver;
}

enum DistributionTarget {
    NONE,
    EXPLICIT,
    VAULT
}

struct Distribution {
    DistributionTarget target;
    address strategy;
    uint128 amount;
    bytes configData;
}

struct CreatorBuyParams {
    uint256 minOutputAmount;
    bytes permitData;
}

struct LaunchTokenState {
    uint8 kind;
    uint8 tokenVersion;
    uint8 externalVenue;
    uint8 dexId;
    uint8 quoteTokenType;
    address quoteTokenAddress;
    uint8 status;
    uint256 circulatingSupply;
    uint256 pendingRemainder;
    address pool;
    uint8 poolType;
    bytes venueData;
    uint256 totalSupply;
}

struct GraduationFloorParams {
    address quoteToken;
    uint256 quotePriceUsd;
    uint256 poolQuote;
    uint256 poolToken;
    uint256 totalSupply;
    address vaultFactory;
}

struct GraduationFloorResultV2 {
    bool meetsFloor;
    uint256 floorUsdWad;
    uint256 quoteUsdWad;
    uint16 multiplierBps;
    bool meetsCreateFloor;
    uint256 createFloorUsdWad;
}

interface IDirectLaunchPortal {
    function launchTaxTokenV2(
        CreateTaxTokenParams calldata p,
        Distribution calldata distribution,
        CreatorBuyParams calldata creatorBuy
    ) external payable returns (address token, address pool);

    function lockSalt(bytes32 salt, uint8 kind) external payable;
    function SALT_LOCK_FEE() external view returns (uint256);
    function getLaunchVault(address token) external view returns (address vault, address vaultFactory);
    function getLaunchToken(address token) external view returns (LaunchTokenState memory state);
    function launchQuoteConfig(uint8 kind, address quoteToken)
        external
        view
        returns (bool enabled, uint256 quotePriceUsd);
    function graduationFloorV2(GraduationFloorParams calldata params)
        external
        view
        returns (GraduationFloorResultV2 memory result);
}

interface IStrategy {
    event FlapDistributionInitialized(address token, uint256 amount);

    function initializeDistribution(address token, uint256 amount, bytes calldata configData, bytes32 salt)
        external;
}

interface ITokenDock {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount, address to) external;
    function balanceOf(address token, address owner) external view returns (uint256);
    function totalReserved(address token) external view returns (uint256);
}
