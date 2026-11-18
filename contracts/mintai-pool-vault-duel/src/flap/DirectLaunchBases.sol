// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VaultUISchema, VaultDataSchema, FactoryPolicy} from "flap/IVaultSchemasV1.sol";
import {LaunchVaultAddresses} from "./LaunchVaultAddresses.sol";

interface IDirectLaunchVaultFactory {
    function newVault(address token, address creator, uint8 launchKind, bytes calldata launchParams)
        external
        returns (address vault);
    function isQuoteTokenSupported(address quoteToken) external view returns (bool);
    function factorySpecVersion() external pure returns (string memory);
    function vaultDataSchema() external pure returns (VaultDataSchema memory);
    function tokenCreationPolicies() external view returns (FactoryPolicy[] memory);
    function upgradeVaultImplementation(address newImplementation) external;
}

interface IDirectLaunchVault {
    function description() external view returns (string memory);
    function vaultUISchema() external pure returns (VaultUISchema memory);
}

/// @notice Storage-free caller checks shared by the Pool Launch vault and factory, as in Flap's
///         `DirectLaunchVaultBase` / `DirectLaunchVaultFactoryBase`.
abstract contract DirectLaunchAccess {
    error NotHub(address caller);
    error NotGuardian(address caller);
    error TokenDockNotConfigured();

    modifier onlyHub() {
        if (msg.sender != _getHub()) revert NotHub(msg.sender);
        _;
    }

    modifier onlyGuardian() {
        if (msg.sender != _getGuardian()) revert NotGuardian(msg.sender);
        _;
    }

    function _getHub() internal view virtual returns (address) {
        return LaunchVaultAddresses.hub();
    }

    function _getGuardian() internal view virtual returns (address) {
        return LaunchVaultAddresses.guardian();
    }

    /// @dev Never cache: the router decides between the open and verified dock per call.
    function _getTokenDockRouter() internal view virtual returns (address dock) {
        dock = LaunchVaultAddresses.tokenDockRouter();
        if (dock == address(0)) revert TokenDockNotConfigured();
    }
}
