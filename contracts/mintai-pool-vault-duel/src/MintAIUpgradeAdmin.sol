// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {DirectLaunchAccess} from "./flap/DirectLaunchBases.sol";

/// @notice Owns every MINT.AI beacon. The Guardian upgrades through here, and the two factories
///         may also call {upgrade} after they have checked the Guardian themselves.
///         This contract is not behind a beacon: the upgrade path stays even if a module upgrade is bad.
contract MintAIUpgradeAdmin is DirectLaunchAccess {
    address public immutable deployer;
    mapping(address => bool) public beaconOf;
    mapping(address => bool) public operator;
    bool public ready;

    error ZeroAddress();
    error NotDeployer();
    error UnknownBeacon();

    constructor() {
        deployer = msg.sender;
    }

    /// @notice System deployer only, and only before {finish}.
    function addBeacon(address beacon) external {
        if (msg.sender != deployer || ready) revert NotDeployer();
        if (beacon == address(0)) revert ZeroAddress();
        beaconOf[beacon] = true;
    }

    /// @notice System deployer only, and only before {finish}. Factories registered here can pass a Guardian check onward.
    function addOperator(address who) external {
        if (msg.sender != deployer || ready) revert NotDeployer();
        if (who == address(0)) revert ZeroAddress();
        operator[who] = true;
    }

    function finish() external {
        if (msg.sender != deployer || ready) revert NotDeployer();
        ready = true;
    }

    /// @notice Point `beacon` at `newImplementation`. Guardian, or a factory that already checked the Guardian.
    function upgrade(address beacon, address newImplementation) external {
        if (msg.sender != _getGuardian() && !operator[msg.sender]) revert NotGuardian(msg.sender);
        if (!beaconOf[beacon]) revert UnknownBeacon();
        if (newImplementation == address(0)) revert ZeroAddress();
        UpgradeableBeacon(beacon).upgradeTo(newImplementation);
    }
}
