// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 ^0.8.20 ^0.8.24;

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol

// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// src/flap/IDirectPoolLaunch.sol

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

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// ../fomo-countdown/src/flap/IVaultSchemasV1.sol

/// @title IVaultSchemasV1
/// @author The Flap Team
/// @notice Shared struct definitions used by VaultFactory and Vault UI schema methods.
///
/// @dev  鈹€鈹€ WHY THIS FILE EXISTS 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
///
/// The Flap protocol allows anyone to create new vault factories.  Any
/// contract that implements `VaultFactoryBaseV2` can be used to launch
/// tokens via VaultPortal 鈥?no on-chain registration is required.
/// Each factory decodes the opaque `vaultData` bytes in
/// `newVault()` differently, and each vault exposes a unique set of
/// user-facing view and write methods.
///
/// Existing vault types (FlapXVault, SplitVault, SnowBallVault,
/// BlackHoleVault) already have purpose-built UIs.  However, the protocol
/// is designed to be extended 鈥?any third-party developer can create a new
/// vault factory and vault implementation without modifying the core
/// contracts or the UI codebase.
///
/// Without a self-describing mechanism, a new vault type would require a
/// custom UI to be built and deployed before users could interact with it.
/// The structs in this file solve this problem by providing an on-chain
/// schema that enables **automatic UI generation for any future vault type**.
///
/// Both `VaultFactoryBaseV2.vaultDataSchema()` and
/// `VaultBaseV2.vaultUISchema()` return structs defined here, allowing a
/// generic UI to render creation forms and vault interaction pages for
/// vault types that did not exist when the UI was built.
///
///
/// 鈹€鈹€ STRUCT CONSOLIDATION 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
///
/// `FieldDescriptor` is the unified leaf type shared by both the factory
/// schema (`VaultDataSchema.fields`) and the vault UI schema
/// (`VaultMethodSchema.inputs` / `VaultMethodSchema.outputs`).  Keeping one
/// struct avoids duplication and ensures the type system is consistent across
/// the protocol.
///
///
/// 鈹€鈹€ HOW THE UI USES VaultDataSchema (factory side) 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
///
///   1. UI obtains the factory address (e.g. from the token-launch event
///      or a directory service).
///   2. UI calls factory.vaultDataSchema() 鈫?gets VaultDataSchema.
///   3. For each field in schema.fields, UI renders an input:
///        "string"   鈫?text input
///        "address"  鈫?address input (with checksum validation)
///        "uint16"   鈫?number input (0鈥?5535)
///        "uint256"  鈫?big-number input
///        "time"     鈫?date/time picker input (alias for uint256;
///                      value is a Unix timestamp in seconds).
///                      When used in outputs, rendered as a
///                      human-readable time string or countdown clock
///        "bool"     鈫?checkbox
///        "bytes"    鈫?hex input
///        "bytes32"  鈫?hex input (32 bytes)
///      For numeric fields, if field.decimals > 0 the UI multiplies the
///      user's input by 10^decimals before encoding.
///        e.g. decimals=18: user types "1" 鈫?encoded value is 1e18
///      If decimals == 0 the raw value is used as-is.
///   4. If schema.isArray == true, UI renders an "Add Item" button for
///      dynamic array entries.
///   5. UI encodes the user input via:
///        If isArray: abi.encode(tuple[])
///        Else:       abi.encode(tuple)
///      using the fieldType values to construct the ABI type string.
///   6. Encoded bytes are passed as `vaultData` in NewTaxTokenWithVaultParams.
///
/// NOTE: The current spec only supports either a single tuple or an array
///       of tuples.
///
///
/// 鈹€鈹€ HOW THE UI USES VaultUISchema (vault side) 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
///
///   1. UI calls vault.vaultUISchema() 鈫?gets VaultUISchema.
///   2. UI displays schema.vaultType as a badge/header and
///      schema.description as subtitle.
///   3. UI always calls vault.description() and displays the result as a
///      dynamic status banner.
///   4. For each method in schema.methods:
///      a. If method.isWriteMethod == false (VIEW):
///         - If method.inputs is empty: call immediately and display results.
///         - If method.inputs is non-empty: render input fields, add a
///           "Query" button.
///           - If method.isInputArray == true, render an "Add Item" button.
///         - For outputs: use field.decimals to format numeric values
///           (e.g. decimals=18: raw 1.5e18 鈫?display "1.5").
///           For "time" fields, display the raw uint256 value as a
///           human-readable time string or a countdown clock.
///         - Derive the ABI type string from outputs[].fieldType +
///           method.isOutputArray.
///         - Use field.name and field.description as column headers/tooltips.
///      b. If method.isWriteMethod == true (WRITE):
///         - Render a form with inputs from method.inputs.
///         - If method.isInputArray == true, render "Add Item" button.
///         - Each input renders based on fieldType:
///             "address" 鈫?address input with checksum validation
///             "uint256" 鈫?big-number input
///             "uint128" 鈫?number input
///             "time"    鈫?date/time picker input (alias for uint256;
///                          value is a Unix timestamp in seconds)
///             "string"  鈫?text input
///             "bytes"   鈫?hex input
///             "bool"    鈫?checkbox
///         - If field.decimals > 0, the UI multiplies the user's
///           human-readable input by 10^decimals before encoding.
///         - If method.approvals is non-empty, BEFORE sending the write
///           transaction the UI executes each ApproveAction in order:
///             i.   Resolve the token address from approval.tokenType:
///                    "taxToken" 鈫?call vault.taxToken()
///                    "lpToken"  鈫?call vault.lpToken()
///                    unknown    鈫?skip (log warning, forward-compatible)
///             ii.  Read the amount from the user's input field named by
///                  approval.amountFieldName (already scaled by decimals).
///             iii. Check current allowance: token.allowance(user, vault).
///                  If already sufficient, skip.
///             iv.  Send token.approve(vault, amount) and wait for
///                  confirmation.
///             v.   Repeat for the next ApproveAction.
///         - After all approvals succeed, send the write transaction.
///         - Add a "Submit" / "Execute" button that sends the transaction.
///         - If method.inputs is empty, just render a single action button.
///   5. All methods are displayed in the order returned by vaultUISchema().
///   6. description() output is polled/refreshed periodically as a live
///      status indicator.

// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
//  Shared Struct Definitions
// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

/// @notice Describes a single field (parameter, return value, or vault-data component).
///
/// @dev   This is the unified leaf type used in both:
///        - `VaultDataSchema.fields`   (factory 鈫?describes vaultData encoding)
///        - `VaultMethodSchema.inputs` / `VaultMethodSchema.outputs`  (vault UI)
///
///        Keeping one struct avoids duplication and ensures the type system is
///        consistent across the protocol.
///
/// @param name        Machine-readable name of the field.
///                    Examples: "xHandle", "recipient", "bps", "user", "amount".
///
/// @param fieldType   Solidity ABI type string for the field.
///                    Examples: "string", "address", "uint16", "uint256", "uint128",
///                    "bool", "bytes", "bytes32".
///                    The special value "time" is an alias for "uint256".
///                    The encoded value is a Unix timestamp in seconds.
///                    For ABI encoding purposes the UI treats "time"
///                    identically to "uint256".
///                    - As an **input**, the UI renders a date/time picker.
///                    - As an **output**, the UI renders the value as a
///                      human-readable time string or a countdown clock.
///                    The special value "msg.value" indicates that the field
///                    represents the native currency amount (in wei) to send
///                    with the transaction.  Rules for this type:
///                    - This field is **NOT** ABI-encoded into the function
///                      call data.  Instead, the UI uses the value as the
///                     call's `value` (i.e `msg.value`).
///                    - It **MUST** only be used for inputs in write methods
///                      (i.e. when `VaultMethodSchema.isWriteMethod == true`).
///                    - Only one "msg.value" field per method is meaningful.
///                    Example 鈥?a payable deposit method:
///                    //   function deposit() public payable
///                    //
///                    //   inputs[0] = FieldDescriptor(
///                    //       "amount", "msg.value",
///                    //       "Amount to deposit (BNB)", 18
///                    //   );
///                    The UI uses this to decide which input widget to render
///                    and how to ABI-encode/decode the value.
///
/// @param description Human-readable explanation of the field, shown as a
///                    label or tooltip in the UI.
///                    Examples: "The Twitter/X handle of the token creator",
///                    "Recipient wallet address",
///                    "Basis points share (10000 = 100%)".
///
/// @param decimals    Decimal precision hint for numeric fields.
///                    - For **factory encoding** (VaultDataSchema context):
///                      If decimals > 0, the UI multiplies the user's input
///                      by 10^decimals before ABI-encoding.
///                      e.g. decimals=18: user types "1" 鈫?encoded as 1e18.
///                      If decimals == 0, the raw value is used as-is.
///                    - For **vault display** (VaultMethodSchema.outputs context):
///                      If decimals > 0, the UI divides the raw on-chain value
///                      by 10^decimals for display.
///                      e.g. decimals=18: raw 1.5e18 鈫?display "1.5".
///                      If decimals == 0, the raw value is displayed.
///                    - For non-numeric fields (string, address, bytes, bool),
///                      this should always be 0.
struct FieldDescriptor {
    string name;
    string fieldType;
    string description;
    uint8 decimals;
}

// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
//  Factory-side: VaultDataSchema
// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

/// @notice Describes the shape of the `vaultData` bytes expected by a
///         VaultFactory's `newVault()` method.
///
/// @dev   A UI calls `factory.vaultDataSchema()` to discover what fields the
///        factory expects, then renders a form accordingly.
///
///        The current spec supports two shapes:
///          鈥?A single tuple   (`isArray == false`)  鈥?e.g. `(string)`
///          鈥?An array of tuples (`isArray == true`)  鈥?e.g. `(address,uint16)[]`
///
///        If `fields` is empty and `isArray` is false, the factory ignores
///        `vaultData` entirely (e.g. SnowBallFactory).
///
/// @param description  Free-form string explaining what the vault does and
///                     what data is required. Shown to the user in the UI.
///
/// @param fields       Ordered list of field descriptors.  Each entry maps to
///                     one component of the ABI-encoded tuple.
///                     For a factory that requires no user input, return an
///                     empty array.
///
/// @param isArray      If true, `vaultData` is ABI-encoded as `tuple[]`
///                     (an array of the tuple described by `fields`).
///                     If false, `vaultData` is ABI-encoded as a single `tuple`.
struct VaultDataSchema {
    string description;
    FieldDescriptor[] fields;
    bool isArray;
}

// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
//  Vault-side: VaultUISchema & supporting types
// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

/// @notice An ERC-20 `approve` action that the UI must execute **before**
///         calling a write method on the vault.
///
/// @dev   The spender is always the vault contract itself.
///
///        Known `tokenType` values:
///          鈥?"taxToken" 鈥?the vault's own tax token (resolved via vault.taxToken())
///          鈥?"lpToken"  鈥?the associated LP token  (resolved via vault.lpToken())
///
///        New token types can be added in the future without changing this
///        struct.  The UI **MUST** ignore any `tokenType` it does not
///        recognise (forward-compatible).
///
///        Workflow for the UI when processing an ApproveAction:
///          1. Resolve the token address from `tokenType`:
///               "taxToken" 鈫?call vault.taxToken()
///               "lpToken"  鈫?call vault.lpToken()
///               unknown    鈫?skip with a warning (forward-compatible)
///          2. Read the amount from the user's input field whose `name`
///             matches `amountFieldName`.  The value should already be
///             scaled by the field's `decimals`.
///          3. Check current allowance: token.allowance(user, vault).
///             If already sufficient, skip.
///          4. Send token.approve(vault, amount) and wait for confirmation.
///
/// @param tokenType       Which token to approve.
///                        e.g. "taxToken", "lpToken".
///
/// @param amountFieldName The `name` of the write method's input
///                        FieldDescriptor whose value should be used as
///                        the approve amount.
///                        e.g. "amount".
struct ApproveAction {
    string tokenType;
    string amountFieldName;
}

/// @notice Describes a single view or write method that the UI should render
///         for a vault.
///
/// @dev   The UI iterates over the `methods` array in `VaultUISchema` and
///        renders each method as either a read-only query panel (view) or an
///        interactive form (write).
///
/// @param name          Solidity method name.
///                      e.g. "claim", "getRecipientsInfo", "stats",
///                      "dispatch", "transitState", "manageByProof".
///
/// @param description   Human-readable explanation of what the method does.
///                      Shown as a subtitle or tooltip in the UI.
///
/// @param inputs        Ordered list of input parameters.
///                      Empty for no-arg methods (e.g. dispatch(), stats()).
///                      Each FieldDescriptor maps to one method parameter.
///
/// @param outputs       Ordered list of return values.
///                      Empty for write methods (tx receipts don't return data
///                      to the UI).
///                      Each FieldDescriptor maps to one return component.
///                      The UI uses `field.decimals` to format numeric values
///                      for display.
///
/// @param approvals     Ordered list of ERC-20 approve actions the UI must
///                      execute **before** sending the write transaction.
///                      The spender is always the vault contract.
///                      Empty for:
///                        鈥?view methods
///                        鈥?write methods that need no prior approval
///
/// @param isInputArray  If true, the method's input is an array of tuples
///                      described by `inputs`.  The UI should render an
///                      "Add Row" button for dynamic array entries.
///
/// @param isOutputArray If true, the method's return value is an array of
///                      tuples described by `outputs`.  The UI should render
///                      results as a table with one row per element.
///
/// @param isWriteMethod If true, the method is state-changing and the UI
///                      should send a transaction.
///                      If false, the method is a view call and the UI
///                      should display the returned data.
struct VaultMethodSchema {
    string name;
    string description;
    FieldDescriptor[] inputs;
    FieldDescriptor[] outputs;
    ApproveAction[] approvals;
    bool isInputArray;
    bool isOutputArray;
    bool isWriteMethod;
}

/// @notice Top-level schema describing the vault's entire UI surface.
///
/// @dev   Returned by `VaultBaseV2.vaultUISchema()`.  The UI uses this to
///        build the complete vault interaction page.
///
///        Rendering algorithm:
///          1. Display `vaultType` as a badge/header.
///          2. Display `description` as a subtitle.
///          3. Always call `vault.description()` and display the result as a
///             dynamic status banner (polled/refreshed periodically).
///          4. Iterate `methods` and render each one according to its
///             `isWriteMethod` flag (see VaultMethodSchema docs above).
///          5. Methods are displayed in the order returned.
///
/// @param vaultType    Human-readable vault type identifier.
///                     e.g. "FlapXVault", "SplitVault", "SnowBallVault",
///                     "BlackHoleVault".
///
/// @param description  Overall explanation of the vault for the UI.
///                     e.g. "Distributes received BNB among a fixed set of
///                     recipients by basis-point shares."
///
/// @param methods      All methods the UI should render.
///                     Ordered 鈥?the UI displays them in this order.
struct VaultUISchema {
    string vaultType;
    string description;
    VaultMethodSchema[] methods;
}

// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
//  Factory-side: FactoryPolicy (VaultFactoryBaseV2 v2.1)
// 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

/// @notice A single constraint on the parameters passed to newTokenV6WithVault.
///
/// @dev    Inspired by AWS IAM policy conditions.  Each FactoryPolicy describes
///         one constraint: "field <target> must satisfy <operator> <value>".
///
///         These policies are **informational only** 鈥?they are intended for
///         UI rendering (inline validation hints, error messages).  The actual
///         enforcement always happens inside `onBeforeNewTokenV6WithVault`.
///
///         Factories that override `onBeforeNewTokenV6WithVault` SHOULD also
///         override `tokenCreationPolicies()` to describe their constraints in
///         this machine-readable form so the UI can surface them proactively.
///
///
/// 鈹€鈹€ FIELD REFERENCE 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
///
/// @param target      The Solidity field name in
///                    IVaultPortalTypes.NewTokenV6WithVaultParams that this
///                    constraint applies to.
///                    Examples: "dividendToken", "dividendBps", "taxBps",
///                    "quoteToken", "migratorType".
///
/// @param operator    The comparison operator.  Supported values:
///                    "eq"    鈥?field must equal value
///                    "neq"   鈥?field must not equal value
///                    "gt"    鈥?field must be strictly greater than value
///                    "gte"   鈥?field must be greater than or equal to value
///                    "lt"    鈥?field must be strictly less than value
///                    "lte"   鈥?field must be less than or equal to value
///                    "in"    鈥?field must be one of a set; `value` is an
///                              ABI-encoded dynamic array of that field's type
///                    "notIn" 鈥?field must not be any of a set (same encoding)
///                    Unknown operators MUST be ignored by the UI (forward-compat).
///
/// @param value       ABI-encoded expected value.
///                    Since `target` identifies a specific field in
///                    NewTokenV6WithVaultParams whose Solidity type is fixed,
///                    the UI already knows the ABI type and can decode `value`
///                    directly without an additional type hint.
///                    For "in" / "notIn", `value` is an ABI-encoded dynamic
///                    array of that field's element type.
///
/// @param description Human-readable explanation shown as a tooltip or inline
///                    validation hint in the UI.
///                    Examples:
///                    "Dividend token must equal the quote token (WBNB)."
///                    "Dividend BPS must be at least 100 (1%)."
///
///
/// 鈹€鈹€ EXAMPLES 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
///
///   // dividendToken must equal WBNB
///   FactoryPolicy({
///       target:      "dividendToken",
///       operator:    "eq",
///       value:       abi.encode(WBNB_ADDRESS),
///       description: "Dividend token must equal the quote token (WBNB)."
///   })
///
///   // dividendBps must be >= 100 (1%)
///   FactoryPolicy({
///       target:      "dividendBps",
///       operator:    "gte",
///       value:       abi.encode(uint256(100)),
///       description: "Dividend BPS must be at least 100 (1%)."
///   })
///
///   // quoteToken must be one of an allowed set
///   FactoryPolicy({
///       target:      "quoteToken",
///       operator:    "in",
///       value:       abi.encode(allowedAddresses),   // address[]
///       description: "Quote token must be WBNB or USDT."
///   })
///
struct FactoryPolicy {
    string target;
    string operator;
    bytes value;
    string description;
}

// ../fomo-countdown/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// src/flap/LaunchVaultAddresses.sol

/// @notice Per-chain Pool Launch addresses, transcribed from the Flap `LaunchVaultAddresses` library.
library LaunchVaultAddresses {
    error UnsupportedChain(uint256 chainId);

    function hub() internal view returns (address) {
        uint256 id = block.chainid;
        if (id == 56 || id == 97) return 0x000042108465206185A077Edc3F3fd2b49060000;
        revert UnsupportedChain(id);
    }

    function guardian() internal view returns (address) {
        if (block.chainid == 56) return 0x9e27098dcD8844bcc6287a557E0b4D09C86B8a4b;
        return 0x00004d58290854c5E9880F4b5B1993c6Ad8b0000;
    }

    function tokenDockRouter() internal view returns (address) {
        uint256 id = block.chainid;
        if (id == 56 || id == 97) return 0x000048E888aBf09f690a952E1b386b2D031a0000;
        revert UnsupportedChain(id);
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // 鈫?`sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // 鈫?`2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// src/MintAIInterfaces.sol

interface IMintAICards {
    function tokenName() external view returns (string memory);
    function tokenSymbol() external view returns (string memory);
    function launching() external view returns (bool);
    function presaleCards(address who) external view returns (uint256);
    function paidMinted() external view returns (uint256);
    function teamUnlockAt(uint256 ordinal) external view returns (uint40);
    function listings(uint256 tokenId) external view returns (address seller, uint96 price);
    function floorHint() external view returns (uint256);
    function nextTick(uint256 from) external view returns (uint256);
    function tickHead(uint256 key) external view returns (uint256);
    function nextListed(uint256 tokenId) external view returns (uint256);
    function onVaultRevenue(uint256 dividendNow, uint256 dividendStream, uint256 ops) external payable;
    function floorBuy(uint256 tokenId) external payable;
}

interface IMintAIVault {
    function buyForMint(address minter, uint256 firstId, uint256 count, uint256 minTokens)
        external
        payable
        returns (uint256 vested);
    function moveCardVest(address to, uint256 id) external;
    function addTeamGrants(address to, uint256 cursor, uint256 count) external;
    function onLaunched(address pair, address router, address launcher_) external;
    function sync() external;
    function bucketLeft(uint8 bucket) external view returns (uint256);
}

interface IMintAIFactory {
    function vaultOf(address token) external view returns (address);
    function launcherFactory() external view returns (address);
    function creatorExtension() external view returns (bytes32 extensionID, bytes32 creatorWord);
    function rejectScam(string calldata name, string calldata symbol) external view;
    function antiScamModule() external view returns (address);
    function marketLogic() external view returns (address);
    function notePresaleBuyer(address buyer) external;
    function presaleBuyerCount() external view returns (uint256);
    function presaleBuyer(uint256 index) external view returns (address);
}

interface IMintAILauncherFactory {
    function launchCreator() external view returns (address);
}

/// @notice Flap's per-chain anti-scam module. The two results are the name and the symbol, in that order.
interface IAntiScam {
    function isScamWord(string calldata name, string calldata symbol)
        external
        view
        returns (bool nameScam, bool symbolScam);
}

interface IMintAIDuel {
    function onTrigger(uint256 requestId) external returns (bool);
    function bindCards(address cards_) external;
    function bindVault(address vault_) external;
    function TRIGGER_DELAY() external view returns (uint256);
}

interface IMintAIUpgrades {
    function upgrade(address beacon, address newImplementation) external;
}

/// @dev Flap Trigger Service. BSC 0xcf4EE25035CF883895110f367F5BA8172416a7F9, BSC testnet
///      0x560E9830926C9e0EB98a59c6b9902383Fc0D9Eb2. Calls back `trigger(requestId)` with at most 2,000,000 gas.
interface IFlapTriggerService {
    function getFee() external view returns (uint256);
    function requestTrigger(uint64 executeAfter) external payable returns (uint256 requestId);
}

interface IV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function sync() external;
}

interface IV2Router {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 amount) external returns (bool);
}

interface ITaxProcessor {
    function dispatch() external;
}

// src/MintAIParams.sol

/// @notice Launch economics shared by the cards, the factory and the vault.
library MintAIParams {
    uint256 internal constant TOTAL_SUPPLY = 777_777_777 ether;
    uint256 internal constant POOL_TOKEN = 124_672_000 ether;
    /// @dev 75% of the 49 BNB presale. The other 25% goes to ops at launch.
    uint256 internal constant POOL_QUOTE = 36.75 ether;
    uint256 internal constant RESERVE = TOTAL_SUPPLY - POOL_TOKEN;

    /// @dev Tokens vested to every presale card and every team card.
    uint256 internal constant CARD_GRANT = 8_440 ether;
    uint256 internal constant PRESALE_CARDS = 20_000;
    uint256 internal constant TEAM_CARDS = 38_888;

    /// @dev Reserve buckets. UNALLOCATED is burned to the dead address inside the launch transaction.
    uint256 internal constant GRANT_BUDGET = (PRESALE_CARDS + TEAM_CARDS) * CARD_GRANT;
    uint256 internal constant LADDER_BUDGET = 58_611_119 ether;
    uint256 internal constant UNALLOCATED = RESERVE - GRANT_BUDGET - LADDER_BUDGET;

    uint16 internal constant TAX_BPS = 200;
    uint32 internal constant TAX_DURATION = type(uint32).max;

    /// @dev Vault revenue split, in bps of what the VAULT slot delivers.
    uint256 internal constant DIVIDEND_BPS = 5_000;
    uint256 internal constant FLOOR_BPS = 3_000;
    uint256 internal constant OPS_BPS = 2_000;

    /// @dev Share of the tokens bought by a post-open mint that is burned; the rest vests to the minter.
    uint256 internal constant MINT_BURN_BPS = 1_000;

    /// @dev Three rungs. 5x and above cannot clear: the presale grant is larger than the pool, so a full
    ///      sell takes the price well below the opening price, and climbing back past 3x already needs the
    ///      pool to hold roughly 68 BNB against the opening token reserve.
    uint256 internal constant LADDER_RUNGS = 3;

    uint8 internal constant BUCKET_GRANT = 0;
    uint8 internal constant BUCKET_LADDER = 1;

    error BadLadderRung();

    /// @dev Tokens in a rung. The first two are equal; the last takes the remainder so the three sum to the budget.
    function ladderRungTokens(uint256 rung) internal pure returns (uint256) {
        if (rung >= LADDER_RUNGS) revert BadLadderRung();
        uint256 base = LADDER_BUDGET / LADDER_RUNGS;
        if (rung + 1 == LADDER_RUNGS) return LADDER_BUDGET - base * (LADDER_RUNGS - 1);
        return base;
    }

    /// @dev 1.5x, 2x, 3x of the opening price, as a fraction.
    function ladderMultiple(uint256 rung) internal pure returns (uint256 num, uint256 den) {
        if (rung == 0) return (3, 2);
        if (rung == 1) return (2, 1);
        if (rung == 2) return (3, 1);
        revert BadLadderRung();
    }

    /// @dev Opening price in BNB wei per 1e18 token wei.
    function openingPrice() internal pure returns (uint256) {
        return POOL_QUOTE * 1e18 / POOL_TOKEN;
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/proxy/Proxy.sol

// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Proxy.sol)

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback
     * function and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`鈥檚 `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`鈥檚 approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`鈥檚 approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// ../fomo-countdown/lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// src/MintAICardsLens.sol

interface IMintAICardsMarket {
    function lastTokenId() external view returns (uint256);
    function nextBidId() external view returns (uint256);
    function listedBits(uint256 word) external view returns (uint256);
    function openBidBits(uint256 word) external view returns (uint256);
    function listings(uint256 tokenId) external view returns (address seller, uint96 price);
    function bids(uint256 bidId) external view returns (address bidder, uint96 price, uint32 remaining);
    function paidMinted() external view returns (uint256);
    function launched() external view returns (bool);
    function launchedToken() external view returns (address);
    function router() external view returns (address);
    function priceOf(uint256 paidIndex) external pure returns (uint256);
    function OPS_BPS() external view returns (uint256);
    function floorHint() external view returns (uint256);
    function tickBits(uint256 word) external view returns (uint256);
    function tickWordBits(uint256 index) external view returns (uint256);
    function tickCount(uint256 tick) external view returns (uint256);
}

/// @notice Read-only paging over the MintAICards order book. Holds no state and no funds.
contract MintAICardsLens {
    struct ListingView {
        uint256 tokenId;
        address seller;
        uint96 price;
    }

    struct BidView {
        uint256 bidId;
        address bidder;
        uint96 price;
        uint32 remaining;
    }

    uint256 private constant MAX_PAGE = 500;
    uint256 private constant MAX_SCAN_WORDS = 3_100;
    uint256 private constant CARD_GRANT = 8_440 ether;
    uint256 private constant PRICE_TICK = 0.00001 ether;
    uint256 private constant MAX_TICK_WORDS = (1 << 20) >> 8;

    /// @notice Exact payment for the next `count` paid cards and the tokens that would vest to the buyer.
    ///         Before launch the grant is exact. After launch it is an estimate at the current pool price:
    ///         router quote, minus the 2% buy tax, minus the 10% burn. Pass a slippage-reduced value as
    ///         `minTokens` to mint.
    function quoteMint(address cards, uint256 count) external view returns (uint256 total, uint256 tokens) {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        total = c.priceOf(c.paidMinted() + 1) * count;
        if (!c.launched()) return (total, CARD_GRANT * count);
        IV2Router r = IV2Router(c.router());
        address[] memory path = new address[](2);
        path[0] = r.WETH();
        path[1] = c.launchedToken();
        uint256 spend = total - total * c.OPS_BPS() / 10_000;
        uint256 out = r.getAmountsOut(spend, path)[1];
        tokens = out * 98 / 100 * 9 / 10;
    }

    /// @notice Lowest ask price and how many cards are listed at it. (0, 0) when nothing is listed.
    function floor(address cards) external view returns (uint256 price, uint256 listed) {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        uint256 h = c.floorHint();
        uint256 word = h >> 8;
        if (word >= MAX_TICK_WORDS) return (0, 0);
        uint256 bits = c.tickBits(word) & (type(uint256).max << (h & 255));
        if (bits == 0) {
            if (++word >= MAX_TICK_WORDS) return (0, 0);
            uint256 s = word >> 8;
            uint256 summary = c.tickWordBits(s) & (type(uint256).max << (word & 255));
            while (summary == 0) {
                if (++s >= MAX_TICK_WORDS >> 8) return (0, 0);
                summary = c.tickWordBits(s);
            }
            word = s << 8;
            while (summary & 1 == 0) {
                summary >>= 1;
                ++word;
            }
            bits = c.tickBits(word);
        }
        uint256 tick = word << 8;
        while (bits & 1 == 0) {
            bits >>= 1;
            ++tick;
        }
        return (tick * PRICE_TICK, c.tickCount(tick));
    }

    /// @notice Open sell orders in token-id order. Start at cursor 0 and pass `next` back until next == end.
    function getActiveListings(address cards, uint256 cursor, uint256 limit)
        external
        view
        returns (ListingView[] memory orders, uint256 next, uint256 end)
    {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        end = c.lastTokenId() + 1;
        uint256[] memory ids;
        (ids, next) = _scan(c, true, cursor, end, limit);
        orders = new ListingView[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            (address seller, uint96 price) = c.listings(ids[i]);
            orders[i] = ListingView(ids[i], seller, price);
        }
    }

    /// @notice Open buy orders in bid-id order. Start at cursor 0 and pass `next` back until next == end.
    function getActiveBids(address cards, uint256 cursor, uint256 limit)
        external
        view
        returns (BidView[] memory orders, uint256 next, uint256 end)
    {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        end = c.nextBidId();
        uint256[] memory ids;
        (ids, next) = _scan(c, false, cursor, end, limit);
        orders = new BidView[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            (address bidder, uint96 price, uint32 remaining) = c.bids(ids[i]);
            orders[i] = BidView(ids[i], bidder, price, remaining);
        }
    }

    function _scan(IMintAICardsMarket c, bool listingsBook, uint256 cursor, uint256 end, uint256 limit)
        private
        view
        returns (uint256[] memory ids, uint256 next)
    {
        if (limit == 0 || limit > MAX_PAGE) limit = MAX_PAGE;
        ids = new uint256[](limit);
        uint256 n;
        uint256 scanned;
        while (cursor < end && n < limit && scanned < MAX_SCAN_WORDS) {
            uint256 word = cursor >> 8;
            uint256 bits = (listingsBook ? c.listedBits(word) : c.openBidBits(word)) >> (cursor & 255);
            while (bits != 0 && n < limit) {
                if (bits & 1 == 1) ids[n++] = cursor;
                bits >>= 1;
                cursor += 1;
            }
            if (bits == 0) cursor = (word + 1) << 8;
            scanned += 1;
        }
        next = cursor < end ? cursor : end;
        assembly {
            mstore(ids, n)
        }
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// src/flap/DirectLaunchBases.sol

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

// ../fomo-countdown/lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol

// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol

// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.20;


/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev The `implementation` of the beacon is invalid.
     */
    error BeaconInvalidImplementation(address implementation);

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the initial owner who can upgrade the beacon.
     */
    constructor(address implementation_, address initialOwner) Ownable(initialOwner) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert BeaconInvalidImplementation(newImplementation);
        }
        _implementation = newImplementation;
        emit Upgraded(newImplementation);
    }
}

// ../fomo-countdown/lib/openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol

// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.20;


/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address can only be set once during construction, and cannot be changed afterwards. It is stored in an
 * immutable variable to avoid unnecessary storage reads, and also in the beacon storage slot specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] so that it can be accessed externally.
 *
 * CAUTION: Since the beacon address can never be changed, you must ensure that you either control the beacon, or trust
 * the beacon to not upgrade the implementation maliciously.
 *
 * IMPORTANT: Do not use the implementation logic to modify the beacon storage slot. Doing so would leave the proxy in
 * an inconsistent state where the beacon storage slot does not match the beacon address.
 */
contract BeaconProxy is Proxy {
    // An immutable address for the beacon to avoid unnecessary SLOADs before each delegate call.
    address private immutable _beacon;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     * - If `data` is empty, `msg.value` must be zero.
     */
    constructor(address beacon, bytes memory data) payable {
        ERC1967Utils.upgradeBeaconToAndCall(beacon, data);
        _beacon = beacon;
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Returns the beacon.
     */
    function _getBeacon() internal view virtual returns (address) {
        return _beacon;
    }
}

// src/MintAIDuel.sol

interface IDuelVaultFactory {
    function launcherFactory() external view returns (address);
}

interface IDuelVault {
    function armDuel() external payable returns (uint256 requestId);
    function burnDuelCard(uint256 id) external;
    function repayDuelTick() external payable;
    function fundTrigger() external payable;
    function duelFee() external view returns (uint256);
    function duelBudget() external view returns (uint256);
}

interface IDuelCards {
    function list(uint256[] calldata tokenIds, uint256[] calldata prices) external;
    function proceedsOwed(address who) external view returns (uint256);
    function withdrawProceeds(address to) external returns (uint256);
}

/// @title MintAIDuel
/// @notice 100 rooms for MINT.AI. Each room holds one waiting card. A player names the room: an empty
///         room waits, and a room that already has someone starts that match. Other rooms stay as they are.
///         A separate 0.1 BNB budget on the vault pays the Flap Trigger fee when it can. Floor tax does
///         not refill that budget. When it cannot cover the fee, the waiting player already deposited
///         half and the joining player deposits the rest. If the budget covers the match, both deposits
///         come back. Wins are stored on the card that won, not on the address. The 6th win of that card
///         burns the card just won and the count on the surviving card returns to zero.
///         The callback is earliest 60 seconds later and reads the previous block. It does not revert.
///         One hour after the match starts, if it still has no winner, settle returns both cards.
///         Deployed behind the vault factory's duel beacon. New variables go at the end.
contract MintAIDuel is Initializable, ReentrancyGuardUpgradeable {
    /// @notice Earliest moment settle can return both cards. The callback may still draw before this.
    uint256 public constant REFUND_DELAY = 1 hours;
    /// @dev Earliest Trigger callback. The vault asks for this delay. The callback reads the previous block.
    uint256 public constant TRIGGER_DELAY = 60;
    uint256 public constant BURN_ON_WIN = 6;
    /// @dev Smallest legal ask. The 6th-win card is listed at this price and burned through the vault's
    ///      existing floorBuy. The price is paid from the trigger reserve and returned in the same transaction.
    uint256 public constant BURN_PRICE = 0.00001 ether;
    /// @dev Rooms 1..100. Each room waits for one card. A started match leaves the room immediately.
    uint256 public constant ROOM_COUNT = 100;

    address public vaultFactory;

    address public cards;
    address public vault;
    uint256 public nextMatch;

    struct Room {
        address player;
        uint256 card;
        uint256 deposit;
    }

    /// @dev Room number the address is waiting in. 0 means this address is not waiting.
    mapping(address => uint256) public waitingRoom;
    mapping(uint256 => Room) private _rooms;

    struct Match {
        address a;
        address b;
        uint256 cardA;
        uint256 cardB;
        uint64 lockBlock;
        uint256 requestId;
        bool open;
    }

    mapping(uint256 => Match) public matches;
    mapping(uint256 => uint256) public requestMatch;
    /// @dev Wins of the card the player fought with. A new card starts at zero. Transferring the card
    ///      keeps the count. The address is not what is counted.
    mapping(uint256 => uint256) public cardWins;
    mapping(address => uint256) public refundOf;
    /// @dev Match start. New storage stays at the end so a later beacon upgrade does not move old fields.
    mapping(uint256 => uint64) public openedAt;

    event CardsBound(address indexed cards);
    event VaultBound(address indexed vault);
    event Waiting(address indexed player, uint256 indexed tokenId, uint256 indexed roomId);
    event WaitingCancelled(address indexed player, uint256 indexed tokenId, uint256 indexed roomId);
    event DuelStarted(
        uint256 indexed matchId,
        address indexed a,
        address indexed b,
        uint256 cardA,
        uint256 cardB,
        uint256 lockBlock,
        uint256 requestId
    );
    event DuelSettled(
        uint256 indexed matchId, address indexed winner, address indexed loser, uint256 wonCard, bool burned, uint256 winsAfter
    );
    event DuelRefunded(uint256 indexed matchId);

    error NotFactory();
    error NotLauncher();
    error NotVault();
    error AlreadyBound();
    error NotBound();
    error SelfDuel();
    error NotWaiting();
    error BadRoom();
    error AlreadyWaiting();
    error NotOpen();
    error TooEarly();
    error HashMissing();
    error ShortPaid();
    error NotSelf();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Vault factory calls this through the proxy constructor.
    function initialize(address vaultFactory_) external initializer {
        __ReentrancyGuard_init();
        if (vaultFactory_ == address(0)) revert NotFactory();
        vaultFactory = vaultFactory_;
    }

    receive() external payable {}

    function bindCards(address cards_) external {
        if (cards != address(0)) revert AlreadyBound();
        if (cards_ == address(0)) revert NotBound();
        if (msg.sender != IDuelVaultFactory(vaultFactory).launcherFactory()) revert NotLauncher();
        cards = cards_;
        emit CardsBound(cards_);
    }

    function bindVault(address vault_) external {
        if (msg.sender != vaultFactory) revert NotFactory();
        if (vault != address(0)) revert AlreadyBound();
        if (vault_ == address(0)) revert NotBound();
        vault = vault_;
        emit VaultBound(vault_);
    }

    /// @notice Who is waiting in `roomId`, the card, and the deposit. An empty room returns zero.
    function roomOf(uint256 roomId) external view returns (address player, uint256 card, uint256 deposit) {
        Room storage room = _rooms[roomId];
        return (room.player, room.card, room.deposit);
    }

    /// @notice Put one card in `roomId` (1..100). An empty room waits. A room with someone else starts
    ///         the match and frees the room. The waiting player deposits half of the current trigger fee.
    ///         The joining player deposits the other half. One address cannot wait in two rooms, and
    ///         cannot play both sides of the same room. Returns 0 when the card is only waiting.
    function enter(uint256 roomId, uint256 tokenId) external payable nonReentrant returns (uint256 matchId) {
        if (cards == address(0) || vault == address(0)) revert NotBound();
        if (roomId == 0 || roomId > ROOM_COUNT) revert BadRoom();
        Room storage room = _rooms[roomId];
        uint256 seated = waitingRoom[msg.sender];
        if (seated != 0) {
            if (seated == roomId && room.player == msg.sender) revert SelfDuel();
            revert AlreadyWaiting();
        }
        uint256 fee = IDuelVault(vault).duelFee();
        uint256 due = room.player == address(0) ? fee / 2 : fee - room.deposit;
        if (msg.value != due) revert ShortPaid();
        IERC721(cards).transferFrom(msg.sender, address(this), tokenId);
        if (room.player == address(0)) {
            room.player = msg.sender;
            room.card = tokenId;
            room.deposit = msg.value;
            waitingRoom[msg.sender] = roomId;
            emit Waiting(msg.sender, tokenId, roomId);
            return 0;
        }
        address host = room.player;
        uint256 hostCard = room.card;
        uint256 hostDeposit = room.deposit;
        room.player = address(0);
        room.card = 0;
        room.deposit = 0;
        waitingRoom[host] = 0;
        uint256 requestId;
        if (IDuelVault(vault).duelBudget() >= fee && fee != 0) {
            requestId = IDuelVault(vault).armDuel();
            _refund(host, hostDeposit);
            _refund(msg.sender, msg.value);
        } else {
            requestId = IDuelVault(vault).armDuel{value: hostDeposit + msg.value}();
        }
        matchId = ++nextMatch;
        matches[matchId] = Match({
            a: host,
            b: msg.sender,
            cardA: hostCard,
            cardB: tokenId,
            lockBlock: uint64(block.number),
            requestId: requestId,
            open: true
        });
        requestMatch[requestId] = matchId;
        openedAt[matchId] = uint64(block.timestamp);
        emit DuelStarted(matchId, host, msg.sender, hostCard, tokenId, block.number, requestId);
    }

    /// @notice Take back the waiting card, its deposit, and the dividend it earned while waiting.
    ///         A started match cannot be cancelled.
    function cancel() external nonReentrant {
        uint256 roomId = waitingRoom[msg.sender];
        if (roomId == 0) revert NotWaiting();
        Room storage room = _rooms[roomId];
        if (room.player != msg.sender) revert NotWaiting();
        uint256 tokenId = room.card;
        uint256 deposit = room.deposit;
        room.player = address(0);
        room.card = 0;
        room.deposit = 0;
        waitingRoom[msg.sender] = 0;
        _give(tokenId, msg.sender);
        _flush(msg.sender);
        _refund(msg.sender, deposit);
        emit WaitingCancelled(msg.sender, tokenId, roomId);
    }

    /// @notice Pull a deposit the contract could not send.
    function withdrawRefund() external nonReentrant {
        uint256 amount = refundOf[msg.sender];
        if (amount == 0) revert ShortPaid();
        refundOf[msg.sender] = 0;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert ShortPaid();
    }

    /// @notice Flap Trigger entry, forwarded by the vault. An id that was never a duel request returns
    ///         false so the vault can reject it. A closed match, a missing hash, or a failed settlement
    ///         returns true and does not revert. The hash is the block before this call.
    function onTrigger(uint256 requestId) external nonReentrant returns (bool) {
        if (msg.sender != vault) revert NotVault();
        uint256 matchId = requestMatch[requestId];
        if (matchId == 0) return false;
        if (!matches[matchId].open) return true;
        bytes32 hash = blockhash(block.number - 1);
        if (hash == bytes32(0)) {
            _refundMatch(matchId);
            return true;
        }
        try this.draw(matchId, hash) {} catch {
            if (matches[matchId].open) _refundMatch(matchId);
        }
        return true;
    }

    /// @dev Trigger-only draw. A direct call reverts. State rolls back if settlement fails.
    function draw(uint256 matchId, bytes32 hash) external {
        if (msg.sender != address(this)) revert NotSelf();
        _draw(matchId, hash);
    }

    /// @notice One hour after the match starts, return both cards if it still has no winner.
    function settle(uint256 matchId) external nonReentrant {
        Match storage m = matches[matchId];
        if (!m.open) revert NotOpen();
        if (block.timestamp < uint256(openedAt[matchId]) + REFUND_DELAY) revert TooEarly();
        _refundMatch(matchId);
    }

    /// @notice Kept for callers. An open match does not reveal its winner before the callback.
    function preview(uint256) external pure returns (address winner, bool ready) {
        return (address(0), false);
    }

    function _refundMatch(uint256 matchId) private {
        Match storage m = matches[matchId];
        if (!m.open) return;
        m.open = false;
        _give(m.cardA, m.a);
        _flush(m.a);
        _give(m.cardB, m.b);
        _flush(m.b);
        emit DuelRefunded(matchId);
    }

    function _draw(uint256 matchId, bytes32 hash) private {
        Match storage m = matches[matchId];
        if (!m.open) revert NotOpen();
        if (hash == bytes32(0)) revert HashMissing();
        bool aWins = _winnerOf(m, hash) == m.a;
        address winner = aWins ? m.a : m.b;
        address loser = aWins ? m.b : m.a;
        uint256 ownCard = aWins ? m.cardA : m.cardB;
        uint256 wonCard = aWins ? m.cardB : m.cardA;
        uint256 n = cardWins[ownCard] + 1;
        bool burned = n == BURN_ON_WIN;
        cardWins[ownCard] = burned ? 0 : n;
        m.open = false;
        _give(ownCard, winner);
        if (burned) _burn(wonCard, winner);
        else _give(wonCard, winner);
        _flush(winner);
        emit DuelSettled(matchId, winner, loser, wonCard, burned, cardWins[ownCard]);
    }

    function _winnerOf(Match memory m, bytes32 hash) private pure returns (address) {
        return uint256(keccak256(abi.encodePacked(hash, m.cardA, m.cardB))) & 1 == 0 ? m.a : m.b;
    }

    function _give(uint256 tokenId, address to) private {
        IERC721(cards).transferFrom(address(this), to, tokenId);
    }

    /// @dev List the card at the minimum ask and burn it through the vault. The ask is returned to the
    ///      trigger reserve. Any dividend the card earned while locked is forwarded to `to`.
    function _burn(uint256 tokenId, address to) private {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory prices = new uint256[](1);
        ids[0] = tokenId;
        prices[0] = BURN_PRICE;
        IDuelCards(cards).list(ids, prices);
        uint256 before = address(this).balance;
        IDuelVault(vault).burnDuelCard(tokenId);
        _pullProceeds();
        uint256 got = address(this).balance - before;
        if (got < BURN_PRICE) revert ShortPaid();
        IDuelVault(vault).repayDuelTick{value: BURN_PRICE}();
        _sendOrReserve(to, got - BURN_PRICE);
    }

    function _flush(address to) private {
        uint256 before = address(this).balance;
        _pullProceeds();
        _sendOrReserve(to, address(this).balance - before);
    }

    function _pullProceeds() private {
        if (IDuelCards(cards).proceedsOwed(address(this)) != 0) {
            IDuelCards(cards).withdrawProceeds(address(this));
        }
    }

    function _sendOrReserve(address to, uint256 amount) private {
        if (amount == 0) return;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) IDuelVault(vault).fundTrigger{value: amount}();
    }

    function _refund(address to, uint256 amount) private {
        if (amount == 0) return;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) refundOf[to] += amount;
    }
}

// src/MintAIUpgradeAdmin.sol

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

// ../fomo-countdown/lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC721
    struct ERC721Storage {
        // Token name
        string _name;

        // Token symbol
        string _symbol;

        mapping(uint256 tokenId => address) _owners;

        mapping(address owner => uint256) _balances;

        mapping(uint256 tokenId => address) _tokenApprovals;

        mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC721StorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

    function _getERC721Storage() private pure returns (ERC721Storage storage $) {
        assembly {
            $.slot := ERC721StorageLocation
        }
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC721Storage storage $ = _getERC721Storage();
        $._name = name_;
        $._symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        ERC721Storage storage $ = _getERC721Storage();
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return $._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        unchecked {
            $._balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                $._balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                $._balances[to] += 1;
            }
        }

        $._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        $._tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        $._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// src/MintAIVault.sol

/**
 * @title MintAIVault
 * @notice Pool Launch vault of MINT.AI. Created by MintAIVaultFactory inside the launch transaction.
 *
 * Reserve (653,105,777 tokens, held in the Token Dock)
 *   - 497,014,720 card grants: 8,440 per presale card (20,000) and per team card (38,888), vested by MintAICards.
 *   - 58,611,119 price-ladder tokens: 3 rungs sold at 1.5x / 2x / 3x the opening price,
 *     only while the 30-minute TWAP is at or above the rung. All proceeds stream to card holders over 7 days.
 *   - 97,479,938 unallocated. Burned to the dead address in the launch transaction, before the dock deposit.
 *   Only MintAICards can release grant tokens, and only within the grant bucket. Nobody can withdraw the reserve.
 *
 * Trading tax (100% of the tax revenue arrives here as BNB, after Flap's protocol fee)
 *   - 50% to card dividends and 20% to the ops wallet, forwarded to MintAICards.
 *   - 30% to the floor fund, held here. It first tops the trigger reserve up to 0.02 BNB; that reserve only
 *     pays the 30-minute floor sweep and the 0.00001 ask of a 6th-win burn. It does not pay duels and it
 *     does not refill the separate 0.1 BNB duel budget.
 *   - BNB already in the vault is split at the start of a dividend claim, a card purchase and a sale into
 *     a bid, and before a post-open mint creates its new cards. sync() and the floor sweep still split too.
 *     receive() stays empty so a tax payout cannot revert.
 *
 * Floor fund (run by the Flap Trigger every 30 minutes, or by anyone through sweepFloor)
 *   - Walks the card market from the lowest price up, buys every card it may and can afford at its ask,
 *     pays the seller the price plus the card's dividend so far, and the card is burned.
 *   - Presale cards and team cards: at most 0.00245 BNB. Their tokens are never touched.
 *   - Post-open paid cards: at most 0.0049 BNB, before and after sell-out. Unclaimed tokens of that card
 *     are burned even if the card was transferred. Tokens already claimed stay with the minter.
 *
 * Post-open mints
 *   - MintAICards sends 75% of every post-open card payment here. It is swapped for tokens on the pool;
 *     10% of the tokens received go to the dead address and 90% stay here and vest to the minter.
 *
 * Token vesting (linear over 5 days, per receiving address, claimed with claimTokens)
 *   - 8,440 reserve tokens per presale card: one fifth at the launch second, the rest over 5 days.
 *   - 8,440 reserve tokens per team card, on the same one-fifth-then-five-days schedule. A slot unlocked
 *     before launch starts at the launch second. A slot unlocked after launch starts at that unlock second.
 *   - 90% of the tokens bought by a post-open mint, from the mint, as one schedule per card.
 *     If the floor fund buys the card, that card's unclaimed tokens are burned.
 */
contract MintAIVault is Initializable, ReentrancyGuardUpgradeable, DirectLaunchAccess, IDirectLaunchVault, IStrategy {
    using SafeERC20 for IERC20;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant BPS = 10_000;
    uint256 public constant TWAP_PERIOD = 30 minutes;
    /// @dev A gap longer than an hour is not a 30-minute price. Both observations restart, and the rung stays closed until a new full window exists.
    uint256 public constant TWAP_STALE = 60 minutes;
    uint256 public constant LADDER_STREAM = 7 days;
    uint256 public constant VEST_PERIOD = 5 days;
    uint256 public constant TRIGGER_WATERLINE = 0.02 ether;
    /// @dev Separate from the floor-sweep reserve. Floor tax never refills it. Players pay the trigger
    ///      fee themselves once this is used up.
    uint256 public constant DUEL_BUDGET_CAP = 0.1 ether;
    /// @dev Earliest duel callback. The callback reads the previous block. Kept equal to MintAIDuel.TRIGGER_DELAY.
    uint256 public constant DUEL_TRIGGER_DELAY = 60;
    uint256 public constant TRIGGER_INTERVAL = 30 minutes;
    /// @dev A request still unanswered this long after it was due may be replaced.
    uint256 internal constant TRIGGER_STALE = 1 hours;
    /// @dev The sweep stops and keeps its place when less gas than this is left (Trigger gives 2,000,000).
    uint256 internal constant SWEEP_GAS_FLOOR = 400_000;
    /// @dev One claim or tokensOf page. A wallet with every team card must call again with a later `from`.
    uint256 internal constant TOKEN_PAGE = 500;
    uint256 internal constant MINT_PRICE = 0.0049 ether;
    uint256 internal constant PRESALE_PRICE = 0.00245 ether;
    uint256 internal constant PRICE_TICK = 0.00001 ether;
    uint256 internal constant MAX_TICK = 1 << 20;

    struct Observation {
        uint32 timestamp;
        uint224 cumulative;
    }

    /// @dev reserve: paid from the grant bucket in the Token Dock; otherwise from bought tokens held here.
    struct Vest {
        uint104 total;
        uint104 claimed;
        uint40 start;
        bool reserve;
    }

    struct CardVest {
        address minter;
        uint96 slot;
    }

    address public token;
    address public cards;
    address public factory;
    address public pair;
    address public router;
    address public wbnb;
    bool public tokenIsToken0;
    bool public distributed;

    uint256[2] public bucketReleased;
    uint256[3] public ladderSold;

    uint256 public totalTaxRevenue;
    uint256 public totalDividendForwarded;
    uint256 public totalFloorForwarded;
    uint256 public totalOpsForwarded;
    uint256 public totalMintBnb;
    uint256 public totalMintBought;
    uint256 public totalMintBurned;
    uint256 public totalLadderRevenue;

    Observation public obsOld;
    Observation public obsNew;

    uint256 public launchTime;
    /// @dev Bought tokens held here that are still owed to minters.
    uint256 public boughtOwed;
    mapping(address => Vest[]) public vests;
    mapping(address => uint256) public presaleClaimed;
    /// @dev Post-open card id => minter and its vest index + 1. One vest per card.
    mapping(uint256 => CardVest) public cardVest;
    uint256 public totalForfeitBurned;

    /// @dev BNB held here on purpose; everything above floorFund + triggerReserve is unrecognized tax.
    uint256 public floorFund;
    uint256 public triggerReserve;
    /// @dev BNB set aside for duel trigger fees. Not part of the floor fund and not refilled by tax.
    uint256 public duelBudget;
    /// @dev Cards owner at the moment the pool opened. Recorded for the launch receipt. It does not pay buyers.
    address public launcher;
    uint256 public pendingTriggerId;
    uint256 public triggerDueAt;
    uint256 public totalFloorSpent;
    uint256 public totalFloorBurned;
    /// @dev Where the last sweep stopped: list key (`tick << 1 | post`) and the next id in it. 0 = from the floor.
    uint256 public sweepKey;
    uint256 public sweepId;
    /// @dev Duel contract deployed with the factories. Set once in initialize.
    address public duel;
    /// @dev Ticks below this were already skipped as not buyable. A cheaper buyable listing still goes first.
    uint256 public sweepMark;
    /// @dev Minimum card ask. A 6th-win burn lists the card at this price and floorBuy burns it.
    uint256 internal constant DUEL_BURN_PRICE = 0.00001 ether;

    event Distributed(uint256 amount);
    event Released(uint8 indexed bucket, address indexed to, uint256 amount);
    event TaxRecognized(uint256 amount, uint256 dividend, uint256 ops, uint256 floor);
    event MintBuy(address indexed minter, uint256 bnbIn, uint256 tokensBought, uint256 tokensBurned);
    event VestAdded(address indexed to, uint256 index, uint256 amount, uint256 start, bool reserve);
    event TokensClaimed(address indexed to, uint256 fromReserve, uint256 fromBought);
    event LadderFilled(uint256 indexed rung, address indexed buyer, uint256 tokens, uint256 cost);
    event Forfeited(uint256 indexed tokenId, address indexed minter, uint256 amount);
    event FloorBought(uint256 indexed tokenId, uint256 price);
    event TriggerFunded(uint256 amount, uint256 reserve);
    event TriggerArmed(uint256 indexed requestId, uint256 executeAfter, uint256 fee);
    event TriggerSkipped(string reason);
    event DuelBudgetFunded(uint256 amount, uint256 budget);

    error NotCards();
    error NotTrigger();
    error UnknownTrigger();
    error WrongToken();
    error AlreadyDistributed();
    error BadDistribution(uint256 received);
    error NotLaunched();
    error AlreadyLaunched();
    error BucketExceeded(uint8 bucket, uint256 left, uint256 requested);
    error BadBucket();
    error BadRung();
    error RungNotReached(uint256 twapPrice, uint256 rungPrice);
    error TwapNotReady();
    error RungSoldOut(uint256 left);
    error WrongPayment(uint256 expected, uint256 sent);
    error PayFailed();
    error BadPair();
    error Slippage(uint256 received, uint256 minimum);
    error NothingToClaim();
    error NotDuel();
    error TriggerUnpaid();
    error BadPrice();
    error NotLauncher();

    modifier onlyCards() {
        if (msg.sender != cards) revert NotCards();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Called by the factory in the same call that deploys the proxy. `token_` has no code yet.
    function initialize(address token_, address cards_, address duel_) external initializer {
        __ReentrancyGuard_init();
        if (duel_ == address(0)) revert NotDuel();
        token = token_;
        cards = cards_;
        factory = msg.sender;
        duel = duel_;
    }

    function version() external pure returns (string memory) {
        return "MINT.AI";
    }

    /// @dev Tax payouts land here. Empty on purpose: a payout must not revert, and Flap's wake
    ///      call must not make an external call. Splitting is done by the actions that already
    ///      run on a user's gas, and by sync() / the floor sweep.
    receive() external payable {}

    // ---------------------------------------------------------------- launch hooks

    function initializeDistribution(address token_, uint256 amount, bytes calldata, bytes32)
        external
        override
        onlyHub
    {
        if (token_ != token) revert WrongToken();
        if (distributed) revert AlreadyDistributed();
        distributed = true;
        IERC20 t = IERC20(token_);
        uint256 before = t.balanceOf(address(this));
        t.safeTransferFrom(msg.sender, address(this), amount);
        uint256 got = t.balanceOf(address(this)) - before;
        if (got != MintAIParams.RESERVE) revert BadDistribution(got);
        // Burn the unallocated remainder in this same transaction. The dock only holds grant and ladder tokens.
        t.safeTransfer(DEAD, MintAIParams.UNALLOCATED);
        uint256 keep = MintAIParams.GRANT_BUDGET + MintAIParams.LADDER_BUDGET;
        if (t.balanceOf(address(this)) != before + keep) revert BadDistribution(t.balanceOf(address(this)));
        address dock = _getTokenDockRouter();
        t.forceApprove(dock, keep);
        ITokenDock(dock).deposit(token_, keep);
        emit FlapDistributionInitialized(token_, amount);
        emit Distributed(got);
    }

    /// @notice Called by MintAICards right after the launch transaction returns the pool.
    function onLaunched(address pair_, address router_, address launcher_) external onlyCards {
        if (pair != address(0)) revert AlreadyLaunched();
        address t0 = IV2Pair(pair_).token0();
        address t1 = IV2Pair(pair_).token1();
        address weth = IV2Router(router_).WETH();
        if (!((t0 == token && t1 == weth) || (t1 == token && t0 == weth))) revert BadPair();
        pair = pair_;
        router = router_;
        wbnb = weth;
        tokenIsToken0 = t0 == token;
        launchTime = block.timestamp;
        if (launcher_ == address(0)) revert NotLauncher();
        launcher = launcher_;
        uint224 cum = uint224(_cumulative());
        obsOld = Observation(uint32(block.timestamp), cum);
        obsNew = obsOld;
    }

    // ---------------------------------------------------------------- cards hooks

    /// @notice `count` grants of 8,440 to `to`. Each uses the presale schedule from launch, or from its own
    ///         unlock second when that unlock is later than launch.
    function addTeamGrants(address to, uint256 cursor, uint256 count) external onlyCards {
        for (uint256 i; i < count; ++i) {
            uint40 unlocked = IMintAICards(cards).teamUnlockAt(cursor + 1 + i);
            if (unlocked == 0) revert NotLaunched();
            uint40 start = unlocked < launchTime ? uint40(launchTime) : unlocked;
            _addVest(to, MintAIParams.CARD_GRANT, true, start);
        }
    }

    /// @notice Swap the mint payment for tokens on the pool. 10% of the tokens go to dead; 90% stay here and
    ///         vest to `minter` over 5 days, one equal schedule per card `firstId .. firstId + count - 1`.
    ///         Reverts if fewer than `minTokens` would vest in total.
    function buyForMint(address minter, uint256 firstId, uint256 count, uint256 minTokens)
        external
        payable
        onlyCards
        nonReentrant
        returns (uint256 vested)
    {
        if (pair == address(0)) revert NotLaunched();
        IERC20 t = IERC20(token);
        uint256 before = t.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = token;
        IV2Router(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0, path, address(this), block.timestamp
        );
        uint256 bought = t.balanceOf(address(this)) - before;
        uint256 burned = bought * MintAIParams.MINT_BURN_BPS / BPS;
        if (burned != 0) t.safeTransfer(DEAD, burned);
        vested = bought - burned;
        if (vested < minTokens) revert Slippage(vested, minTokens);
        boughtOwed += vested;
        uint256 share = vested / count;
        for (uint256 i; i < count; ++i) {
            uint256 amount = i + 1 == count ? vested - share * i : share;
            cardVest[firstId + i] = CardVest(minter, uint96(vests[minter].length + 1));
            _addVest(minter, amount, false, uint40(block.timestamp));
        }
        totalMintBnb += msg.value;
        totalMintBought += bought;
        totalMintBurned += burned;
        emit MintBuy(minter, msg.value, bought, burned);
        // The mint payment has been swapped away. Any tax BNB that landed during the swap is split here.
        // Tax that was already waiting was split before these new cards were minted.
        _recognize();
        _poke();
        _arm();
    }

    /// @notice For card `id`: the highest ask the floor fund pays, and the still-locked tokens a floor sale burns.
    ///         Tokens already unlocked stay claimable by the address that held the card then. The address argument is unused.
    function floorLimit(uint256 id, address) external view returns (uint256 maxPrice, uint256 forfeit) {
        CardVest memory link = cardVest[id];
        if (link.slot == 0) return (PRESALE_PRICE, 0);
        maxPrice = MINT_PRICE;
        Vest memory v = vests[link.minter][link.slot - 1];
        uint256 released = _scheduleReleased(v);
        if (released < v.claimed) released = v.claimed;
        forfeit = v.total - released;
    }

    // ---------------------------------------------------------------- token vesting

    /// @notice Claim what has vested: the presale grant plus schedules `from` .. `from + count - 1`.
    ///         `count` 0 means the next 500 schedules, not the rest of a long array.
    function claimTokens(uint256 from, uint256 count) external nonReentrant returns (uint256 amount) {
        if (pair == address(0)) revert NotLaunched();
        uint256 fromReserve;
        uint256 fromBought;
        uint256 presale = IMintAICards(cards).presaleCards(msg.sender) * MintAIParams.CARD_GRANT;
        if (presale != 0) {
            uint256 due = _presaleReleased(presale) - presaleClaimed[msg.sender];
            presaleClaimed[msg.sender] += due;
            fromReserve = due;
        }
        Vest[] storage vs = vests[msg.sender];
        uint256 end = vs.length;
        if (from > end) from = end;
        uint256 n = count == 0 || count > TOKEN_PAGE ? TOKEN_PAGE : count;
        if (end - from > n) end = from + n;
        for (uint256 i = from; i < end; ++i) {
            Vest storage v = vs[i];
            uint256 due = _scheduleReleased(v) - v.claimed;
            if (due == 0) continue;
            v.claimed += uint104(due);
            if (v.reserve) fromReserve += due;
            else fromBought += due;
        }
        amount = fromReserve + fromBought;
        if (amount == 0) revert NothingToClaim();
        if (fromReserve != 0) _release(MintAIParams.BUCKET_GRANT, msg.sender, fromReserve);
        if (fromBought != 0) {
            boughtOwed -= fromBought;
            IERC20(token).safeTransfer(msg.sender, fromBought);
        }
        emit TokensClaimed(msg.sender, fromReserve, fromBought);
    }

    function vestCount(address who) external view returns (uint256) {
        return vests[who].length;
    }

    /// @notice First page of `who`. A wallet past 500 schedules must use `tokensOf(who, from, count)`.
    function tokensOf(address who)
        external
        view
        returns (uint256 total, uint256 claimed, uint256 claimable, uint256 locked)
    {
        return _tokensOf(who, 0, 0);
    }

    /// @notice One page of `who`'s schedules, starting at `from`. `count` 0 means 500.
    ///         The presale grant is included only when `from` is 0, so later pages do not count it again.
    function tokensOf(address who, uint256 from, uint256 count)
        external
        view
        returns (uint256 total, uint256 claimed, uint256 claimable, uint256 locked)
    {
        return _tokensOf(who, from, count);
    }

    function _tokensOf(address who, uint256 from, uint256 count)
        private
        view
        returns (uint256 total, uint256 claimed, uint256 claimable, uint256 locked)
    {
        uint256 done;
        if (from == 0) {
            total = IMintAICards(cards).presaleCards(who) * MintAIParams.CARD_GRANT;
            claimed = presaleClaimed[who];
            done = _presaleReleased(total);
        }
        Vest[] storage vs = vests[who];
        uint256 end = vs.length;
        if (from > end) from = end;
        uint256 n = count == 0 || count > TOKEN_PAGE ? TOKEN_PAGE : count;
        if (end - from > n) end = from + n;
        for (uint256 i = from; i < end; ++i) {
            Vest memory v = vs[i];
            total += v.total;
            claimed += v.claimed;
            done += _scheduleReleased(v);
        }
        claimable = done - claimed;
        locked = total - done;
    }

    // ---------------------------------------------------------------- public keepers

    /// @notice Forward tax that arrived since the last sync: dividend, floor fund and ops shares.
    function sync() external nonReentrant {
        _recognize();
        _poke();
        _arm();
    }

    /// @notice Flap Trigger callback. The booked floor id sweeps the market. Any other id that belongs to a
    ///         duel settles that match. The duel calls back into this vault, so those paths are not guarded again.
    function trigger(uint256 requestId) external nonReentrant {
        if (msg.sender != _triggerService()) revert NotTrigger();
        if (requestId != 0 && requestId == pendingTriggerId) {
            pendingTriggerId = 0;
            _recognize();
            _sweep();
            _poke();
            _arm();
            return;
        }
        if (!IMintAIDuel(duel).onTrigger(requestId)) revert UnknownTrigger();
    }

    /// @notice Book a duel callback 60 seconds out. The 0.1 BNB budget pays the fee when it covers it.
    ///         Otherwise the duel forwards the fee paid by the two players. The floor reserve is not used.
    function armDuel() external payable nonReentrant returns (uint256 requestId) {
        if (msg.sender != duel) revert NotDuel();
        address svc = _triggerService();
        if (svc == address(0)) revert NotTrigger();
        uint256 fee = IFlapTriggerService(svc).getFee();
        if (fee == 0) revert TriggerUnpaid();
        if (duelBudget >= fee) {
            if (msg.value != 0) revert WrongPayment(0, msg.value);
            duelBudget -= fee;
        } else if (msg.value != fee) {
            revert WrongPayment(fee, msg.value);
        }
        uint64 when = uint64(block.timestamp + IMintAIDuel(duel).TRIGGER_DELAY());
        requestId = IFlapTriggerService(svc).requestTrigger{value: fee}(when);
        if (requestId == 0) revert TriggerUnpaid();
        emit TriggerArmed(requestId, when, fee);
    }

    /// @notice Current Flap Trigger fee. Zero when this chain has no trigger service.
    function duelFee() external view returns (uint256) {
        address svc = _triggerService();
        if (svc == address(0)) return 0;
        return IFlapTriggerService(svc).getFee();
    }

    /// @notice Add BNB to the duel budget, up to 0.1 BNB. Anything above the cap is returned.
    ///         Tax recognition never calls this.
    function fundDuelBudget() external payable nonReentrant {
        uint256 room = DUEL_BUDGET_CAP > duelBudget ? DUEL_BUDGET_CAP - duelBudget : 0;
        uint256 take = msg.value > room ? room : msg.value;
        duelBudget += take;
        uint256 back = msg.value - take;
        if (back != 0) {
            (bool ok,) = msg.sender.call{value: back}("");
            if (!ok) revert PayFailed();
        }
        emit DuelBudgetFunded(take, duelBudget);
    }

    /// @notice Burn a card the duel listed at the minimum ask. `floorBuy` pays that ask back to the duel,
    ///         which returns it through {repayDuelTick} in the same transaction.
    function burnDuelCard(uint256 id) external {
        if (msg.sender != duel) revert NotDuel();
        if (IERC721(cards).ownerOf(id) != duel) revert NotDuel();
        (address seller, uint96 price) = IMintAICards(cards).listings(id);
        if (seller != duel || price != DUEL_BURN_PRICE) revert BadPrice();
        if (triggerReserve < DUEL_BURN_PRICE) revert TriggerUnpaid();
        CardVest memory link = cardVest[id];
        triggerReserve -= DUEL_BURN_PRICE;
        IMintAICards(cards).floorBuy{value: DUEL_BURN_PRICE}(id);
        if (link.slot != 0) _forfeit(id, link.minter, link.slot);
    }

    /// @notice Duel-only return of the burn ask into the trigger reserve.
    function repayDuelTick() external payable {
        if (msg.sender != duel) revert NotDuel();
        if (msg.value != DUEL_BURN_PRICE) revert WrongPayment(DUEL_BURN_PRICE, msg.value);
        triggerReserve += msg.value;
    }

    /// @notice Same work as the trigger, paid by the caller. Stops when gas runs low and keeps its place.
    function sweepFloor() external nonReentrant returns (uint256 bought) {
        _recognize();
        bought = _sweep();
        _poke();
        _arm();
    }

    /// @notice Add BNB to the trigger reserve. It only pays Flap Trigger fees.
    function fundTrigger() external payable nonReentrant {
        triggerReserve += msg.value;
        emit TriggerFunded(msg.value, triggerReserve);
        _arm();
    }

    /// @notice Ask the tax processor to pay out, then sync. A failed dispatch does not block the sync.
    function dispatchAndSync() external nonReentrant {
        if (pair != address(0)) {
            (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSignature("taxProcessor()"));
            if (ok && ret.length >= 32) {
                address proc = abi.decode(ret, (address));
                try ITaxProcessor(proc).dispatch() {} catch {}
            }
        }
        _recognize();
        _poke();
        _arm();
    }

    /// @notice Refresh the TWAP observation. Anyone may call; it is also refreshed by sync / mints / ladder.
    function poke() external {
        _poke();
    }

    /// @notice Buy `amount` ladder tokens of `rung` at the rung price. The rung opens only while the
    ///         30-minute TWAP is at or above it. Proceeds stream to card holders over 7 days.
    function buyLadder(uint256 rung, uint256 amount) external payable nonReentrant returns (uint256 cost) {
        if (pair == address(0)) revert NotLaunched();
        if (rung >= MintAIParams.LADDER_RUNGS || amount == 0) revert BadRung();
        uint256 left = MintAIParams.ladderRungTokens(rung) - ladderSold[rung];
        if (amount > left) revert RungSoldOut(left);
        uint256 price = rungPrice(rung);
        _poke();
        uint256 twap = twapPrice();
        if (twap < price) revert RungNotReached(twap, price);
        cost = (amount * price + 1e18 - 1) / 1e18;
        if (msg.value < cost) revert WrongPayment(cost, msg.value);
        ladderSold[rung] += amount;
        totalLadderRevenue += cost;
        _release(MintAIParams.BUCKET_LADDER, msg.sender, amount);
        IMintAICards(cards).onVaultRevenue{value: cost}(0, cost, 0);
        if (msg.value > cost) {
            (bool ok,) = msg.sender.call{value: msg.value - cost}("");
            if (!ok) revert PayFailed();
        }
        emit LadderFilled(rung, msg.sender, amount, cost);
        _poke();
    }

    // ---------------------------------------------------------------- views

    function bucketLeft(uint8 bucket) public view returns (uint256) {
        return _budget(bucket) - bucketReleased[bucket];
    }

    function rungPrice(uint256 rung) public pure returns (uint256) {
        (uint256 num, uint256 den) = MintAIParams.ladderMultiple(rung);
        return MintAIParams.POOL_QUOTE * 1e18 * num / (MintAIParams.POOL_TOKEN * den);
    }

    /// @notice BNB wei per 1e18 token wei, averaged since the older observation (at least 30 minutes).
    function twapPrice() public view returns (uint256) {
        Observation memory o = obsOld;
        uint256 elapsed = block.timestamp - o.timestamp;
        if (elapsed < TWAP_PERIOD) {
            o = obsNew;
            elapsed = block.timestamp - o.timestamp;
        }
        if (o.timestamp == 0 || elapsed < TWAP_PERIOD || elapsed > TWAP_STALE) revert TwapNotReady();
        uint256 avg;
        unchecked {
            avg = (_cumulative() - o.cumulative) / elapsed;
        }
        return (avg * 1e18) >> 112;
    }

    function spotPrice() public view returns (uint256) {
        (uint256 q, uint256 t) = _reserves();
        return q * 1e18 / t;
    }

    /// @notice BNB waiting for sync(): the balance above the floor fund, the trigger reserve and the duel budget.
    function unrecognizedTax() public view returns (uint256) {
        uint256 held = floorFund + triggerReserve + duelBudget;
        uint256 bal = address(this).balance;
        return bal > held ? bal - held : 0;
    }

    function triggerService() external view returns (address) {
        return _triggerService();
    }

    function description() public pure override returns (string memory) {
        return "Presale: 20,000 cards at 0.00245 BNB. Unsold after 7 days can be fully refunded. After launch, "
            "0.0049 BNB per card. 25% of each mint payment goes to operations. Each presale card and team card "
            "receives 8,440 tokens. The 2% tax splits 50% to holders, 30% to the floor, and 20% to operations. "
            "Market fee is 1%.";
    }

    function vaultUISchema() public pure override returns (VaultUISchema memory schema) {
        schema.vaultType = "MINT.AI";
        schema.description = "";
        schema.methods = new VaultMethodSchema[](10);
        schema.methods[0].name = "dispatchAndSync";
        schema.methods[0].isWriteMethod = true;
        schema.methods[1].name = "buyLadder";
        schema.methods[1].inputs = new FieldDescriptor[](3);
        schema.methods[1].inputs[0] = FieldDescriptor("rung", "uint256", "", 0);
        schema.methods[1].inputs[1] = FieldDescriptor("amount", "uint256", "", 18);
        schema.methods[1].inputs[2] = FieldDescriptor("value", "msg.value", "", 18);
        schema.methods[1].isWriteMethod = true;
        schema.methods[2].name = "twapPrice";
        schema.methods[2].outputs = new FieldDescriptor[](1);
        schema.methods[2].outputs[0] = FieldDescriptor("price", "uint256", "", 18);
        schema.methods[3].name = "claimTokens";
        schema.methods[3].inputs = new FieldDescriptor[](2);
        schema.methods[3].inputs[0] = FieldDescriptor("from", "uint256", "", 0);
        schema.methods[3].inputs[1] = FieldDescriptor("count", "uint256", "", 0);
        schema.methods[3].isWriteMethod = true;
        _fillPagedMethods(schema.methods);
    }

    function _fillPagedMethods(VaultMethodSchema[] memory methods) private pure {
        methods[4].name = "tokensOf";
        methods[4].inputs = new FieldDescriptor[](3);
        methods[4].inputs[0] = FieldDescriptor("who", "address", "", 0);
        methods[4].inputs[1] = FieldDescriptor("from", "uint256", "", 0);
        methods[4].inputs[2] = FieldDescriptor("count", "uint256", "", 0);
        methods[5].name = "floorLimit";
        methods[5].inputs = new FieldDescriptor[](1);
        methods[5].inputs[0] = FieldDescriptor("id", "uint256", "", 0);
        methods[6].name = "sweepFloor";
        methods[6].isWriteMethod = true;
        methods[7].name = "sync";
        methods[7].isWriteMethod = true;
        methods[8].name = "fundDuelBudget";
        methods[8].isWriteMethod = true;
        methods[9].name = "fundTrigger";
        methods[9].isWriteMethod = true;
    }

    // ---------------------------------------------------------------- internals

    function _recognize() private {
        uint256 fresh = unrecognizedTax();
        if (fresh == 0 || pair == address(0)) return;
        uint256 toFloor = fresh * MintAIParams.FLOOR_BPS / BPS;
        uint256 toOps = fresh * MintAIParams.OPS_BPS / BPS;
        uint256 toDividend = fresh - toFloor - toOps;
        totalTaxRevenue += fresh;
        totalDividendForwarded += toDividend;
        totalFloorForwarded += toFloor;
        totalOpsForwarded += toOps;
        uint256 reserve = triggerReserve;
        uint256 toFund = toFloor;
        if (reserve < TRIGGER_WATERLINE) {
            uint256 top = TRIGGER_WATERLINE - reserve;
            if (top > toFund) top = toFund;
            triggerReserve = reserve + top;
            toFund -= top;
            emit TriggerFunded(top, reserve + top);
        }
        floorFund += toFund;
        IMintAICards(cards).onVaultRevenue{value: toDividend + toOps}(toDividend, 0, toOps);
        emit TaxRecognized(fresh, toDividend, toOps, toFloor);
    }

    /// @dev Spend the floor fund from the cheapest listing up. Per price tick, presale and team cards first, then
    ///      post-open cards. A price above that card's cap is skipped, and {sweepMark} remembers that skip so the
    ///      next call does not walk those prices again. The cheapest buyable tick still goes before the saved card.
    ///      A seller callback that unlinks the saved successor restarts the same tick from its head. Ends when the
    ///      next price is above the fund or above 0.0049, or keeps its place when gas runs low.
    function _sweep() private returns (uint256 bought) {
        if (pair == address(0)) return 0;
        IMintAICards c = IMintAICards(cards);
        uint256 fund = floorFund;
        uint256 key = sweepKey;
        uint256 id = sweepId;
        if (id != 0) {
            (address s, uint96 p) = c.listings(id);
            if (s == address(0) || p / PRICE_TICK != key >> 1) key = 0;
        }
        uint256 hint = c.floorHint();
        uint256 leftTick = sweepMark;
        if (leftTick < hint) leftTick = hint;
        uint256 first = c.nextTick(hint);
        if (first < leftTick && first < MAX_TICK) {
            uint256 firstPrice = first * PRICE_TICK;
            uint256 firstPre = c.tickHead(first << 1);
            uint256 firstPost = c.tickHead((first << 1) | 1);
            bool firstPreOk = firstPre != 0 && firstPrice <= PRESALE_PRICE;
            bool firstPostOk = firstPost != 0 && firstPrice <= MINT_PRICE;
            if (firstPreOk || firstPostOk) {
                key = 0;
                leftTick = first;
            }
        }
        if (key == 0) {
            key = c.nextTick(leftTick) << 1;
            id = key >> 1 < MAX_TICK ? c.tickHead(key) : 0;
        }
        uint256 spent;
        bool finished;
        while (true) {
            uint256 cheapest = c.nextTick(leftTick);
            if (cheapest < (key >> 1)) {
                uint256 cheapPrice = cheapest * PRICE_TICK;
                uint256 pre = cheapest < MAX_TICK ? c.tickHead(cheapest << 1) : 0;
                uint256 postHead = cheapest < MAX_TICK ? c.tickHead((cheapest << 1) | 1) : 0;
                bool preOk = pre != 0 && cheapPrice <= PRESALE_PRICE;
                bool postOk = postHead != 0 && cheapPrice <= MINT_PRICE;
                if (preOk || postOk) {
                    key = cheapest << 1;
                    id = preOk ? pre : postHead;
                    if (!preOk) key |= 1;
                } else if (cheapest >= MAX_TICK) {
                    (key, id) = (0, 0);
                    finished = true;
                    break;
                } else {
                    leftTick = cheapest + 1;
                    if (gasleft() < SWEEP_GAS_FLOOR) break;
                    continue;
                }
            }
            uint256 tick = key >> 1;
            uint256 price = tick * PRICE_TICK;
            if (tick >= MAX_TICK || price > fund || price > MINT_PRICE) {
                (key, id) = (0, 0);
                finished = true;
                break;
            }
            if (gasleft() < SWEEP_GAS_FLOOR) break;
            bool post = key & 1 == 1;
            if (id == 0 || (!post && price > PRESALE_PRICE)) {
                if (post) leftTick = tick + 1;
                key = post ? c.nextTick(tick + 1) << 1 : key | 1;
                id = key >> 1 < MAX_TICK ? c.tickHead(key) : 0;
                continue;
            }
            uint256 next = c.nextListed(id);
            CardVest memory link;
            if (post) link = cardVest[id];
            bool filled;
            try c.floorBuy{value: price}(id) {
                filled = true;
                fund -= price;
                spent += price;
                ++bought;
                emit FloorBought(id, price);
                if (link.slot != 0) _forfeit(id, link.minter, link.slot);
            } catch {}
            if (filled && next != 0) {
                (address seller,) = c.listings(next);
                id = seller == address(0) ? (key >> 1 < MAX_TICK ? c.tickHead(key) : 0) : next;
            } else {
                id = next;
            }
        }
        (sweepKey, sweepId) = (key, id);
        sweepMark = finished ? hint : leftTick;
        if (spent != 0) {
            floorFund = fund;
            totalFloorSpent += spent;
            totalFloorBurned += bought;
        }
    }

    /// @dev Burn the still-locked bought tokens of card `id`. Tokens already vested stay with `minter`.
    ///      A vest parked on the duel has nobody to claim it, so the whole remainder burns with the card.
    function _forfeit(uint256 id, address minter, uint256 slot) private {
        Vest storage v = vests[minter][slot - 1];
        uint256 locked;
        if (minter == duel) {
            locked = uint256(v.total) - v.claimed;
            v.claimed = v.total;
            v.start = type(uint40).max;
        } else {
            uint256 released = _scheduleReleased(v);
            if (released < v.claimed) released = v.claimed;
            locked = v.total - released;
            v.total = uint104(released);
            v.start = type(uint40).max;
        }
        delete cardVest[id];
        if (locked != 0) {
            boughtOwed -= locked;
            totalForfeitBurned += locked;
            IERC20(token).safeTransfer(DEAD, locked);
            emit Forfeited(id, minter, locked);
        }
    }

    /// @dev A plain transfer. Already-unlocked tokens stay with the current holder. The locked remainder
    ///      follows the card and finishes at the original end. Presale and team grants have no card link.
    ///      The duel cannot claim, so a card leaving it takes the whole remaining schedule.
    function moveCardVest(address to, uint256 id) external onlyCards {
        if (to == address(0)) return;
        CardVest memory link = cardVest[id];
        if (link.slot == 0 || to == link.minter) return;
        Vest storage old = vests[link.minter][link.slot - 1];
        if (link.minter == duel) {
            cardVest[id] = CardVest(to, uint96(vests[to].length + 1));
            vests[to].push(old);
            old.total = 0;
            old.claimed = 0;
            old.start = type(uint40).max;
            return;
        }
        uint256 released = _scheduleReleased(old);
        if (released < old.claimed) released = old.claimed;
        uint256 locked = uint256(old.total) - released;
        uint40 start0 = old.start;
        old.total = uint104(released);
        old.start = type(uint40).max;
        if (locked == 0) return;
        uint256 elapsed = block.timestamp > start0 ? block.timestamp - uint256(start0) : 0;
        uint256 credit = locked * elapsed / (VEST_PERIOD - elapsed);
        cardVest[id] = CardVest(to, uint96(vests[to].length + 1));
        vests[to].push(Vest(uint104(locked + credit), uint104(credit), start0, false));
    }

    /// @dev Book the next Flap Trigger run, paid from the trigger reserve. A request is replaced only once it is
    ///      TRIGGER_STALE past due. Never reverts.
    function _arm() private {
        if (pair == address(0)) return;
        if (pendingTriggerId != 0 && block.timestamp < triggerDueAt + TRIGGER_STALE) return;
        address svc = _triggerService();
        if (svc == address(0)) return;
        uint256 fee;
        try IFlapTriggerService(svc).getFee() returns (uint256 f) {
            fee = f;
        } catch {
            emit TriggerSkipped("fee");
            return;
        }
        if (fee > triggerReserve) {
            emit TriggerSkipped("reserve");
            return;
        }
        uint256 when = block.timestamp + TRIGGER_INTERVAL;
        try IFlapTriggerService(svc).requestTrigger{value: fee}(uint64(when)) returns (uint256 requestId) {
            // The fee has already left. Count it even when the service returns no request id.
            triggerReserve -= fee;
            if (requestId == 0) {
                emit TriggerSkipped("id");
                return;
            }
            pendingTriggerId = requestId;
            triggerDueAt = when;
            emit TriggerArmed(requestId, when, fee);
        } catch {
            emit TriggerSkipped("request");
        }
    }

    function _triggerService() private view returns (address) {
        if (block.chainid == 56) return 0xcf4EE25035CF883895110f367F5BA8172416a7F9;
        if (block.chainid == 97) return 0x560E9830926C9e0EB98a59c6b9902383Fc0D9Eb2;
        return address(0);
    }

    function _addVest(address to, uint256 amount, bool reserve, uint40 start) private {
        Vest[] storage vs = vests[to];
        emit VestAdded(to, vs.length, amount, start, reserve);
        vs.push(Vest(uint104(amount), 0, start, reserve));
    }

    /// @dev Presale grants only. One fifth is released at the launch second. The other four fifths
    ///      vest linearly over 5 days from that same second.
    function _presaleReleased(uint256 total) private view returns (uint256) {
        if (total == 0 || pair == address(0)) return 0;
        return _grantReleased(total, launchTime);
    }

    /// @dev Team grants use the presale shape. Bought-token schedules stay a straight five-day line.
    ///      `start == type(uint40).max` means the locked part was forfeited and what remains is already released.
    function _scheduleReleased(Vest memory v) private view returns (uint256) {
        if (v.start == type(uint40).max) return v.total;
        if (v.reserve) return _grantReleased(v.total, v.start);
        return _vested(v.total, v.start);
    }

    /// @dev One fifth at `start`, the other four fifths linear over 5 days from that same second.
    function _grantReleased(uint256 total, uint256 start) private view returns (uint256) {
        if (total == 0 || block.timestamp < start) return 0;
        uint256 upfront = total / 5;
        return upfront + _vested(total - upfront, start);
    }

    function _vested(uint256 total, uint256 start) private view returns (uint256) {
        if (block.timestamp <= start) return 0;
        uint256 dt = block.timestamp - start;
        return dt >= VEST_PERIOD ? total : total * dt / VEST_PERIOD;
    }

    function _release(uint8 bucket, address to, uint256 amount) private {
        if (amount == 0) return;
        uint256 left = bucketLeft(bucket);
        if (amount > left) revert BucketExceeded(bucket, left, amount);
        bucketReleased[bucket] += amount;
        ITokenDock(_getTokenDockRouter()).withdraw(token, amount, to);
        emit Released(bucket, to, amount);
    }

    function _budget(uint8 bucket) private pure returns (uint256) {
        if (bucket == MintAIParams.BUCKET_GRANT) return MintAIParams.GRANT_BUDGET;
        if (bucket == MintAIParams.BUCKET_LADDER) return MintAIParams.LADDER_BUDGET;
        revert BadBucket();
    }

    function _poke() private {
        if (pair == address(0)) return;
        uint256 age = block.timestamp - obsNew.timestamp;
        if (age < TWAP_PERIOD) return;
        uint224 cum = uint224(_cumulative());
        if (age > TWAP_STALE) {
            obsOld = Observation(uint32(block.timestamp), cum);
            obsNew = obsOld;
            return;
        }
        obsOld = obsNew;
        obsNew = Observation(uint32(block.timestamp), cum);
    }

    /// @dev Pool's quote-per-token cumulative price (UQ112x112 * seconds), extrapolated to now.
    function _cumulative() private view returns (uint256 cum) {
        (uint112 r0, uint112 r1, uint32 last) = IV2Pair(pair).getReserves();
        cum = tokenIsToken0 ? IV2Pair(pair).price0CumulativeLast() : IV2Pair(pair).price1CumulativeLast();
        uint32 nowTs = uint32(block.timestamp);
        if (last != nowTs && r0 != 0 && r1 != 0) {
            unchecked {
                uint32 dt = nowTs - last;
                cum += tokenIsToken0 ? ((uint256(r1) << 112) / r0) * dt : ((uint256(r0) << 112) / r1) * dt;
            }
        }
    }

    function _reserves() private view returns (uint256 quote, uint256 tok) {
        (uint112 r0, uint112 r1,) = IV2Pair(pair).getReserves();
        (quote, tok) = tokenIsToken0 ? (uint256(r1), uint256(r0)) : (uint256(r0), uint256(r1));
    }
}

// src/MintAICardsBase.sol

/// @notice Storage and shared accounting for the cards proxy.
///         MintAICardMarket delegatecalls into this same layout. Do not reorder or insert variables.
abstract contract MintAICardsBase is Initializable, ReentrancyGuardUpgradeable, ERC721Upgradeable {
    struct Listing {
        address seller;
        uint96 price;
    }

    struct Bid {
        address bidder;
        uint96 price;
        uint32 remaining;
    }

    uint256 public constant PAID_CAP = 738_889;
    uint256 internal constant TEAM_CAP = 38_888;
    uint256 internal constant FIRST_BATCH = 20_000;
    uint256 internal constant PRESALE_PRICE = 0.00245 ether;
    uint256 public constant MINT_PRICE = 0.0049 ether;
    uint256 internal constant UNLOCK_EVERY = 19;
    uint256 public constant OPS_BPS = 2_500;
    uint256 internal constant MARKET_FEE_BPS = 100;
    uint256 internal constant BPS = 10_000;
    uint256 internal constant MAX_MINT_PER_TX = 10;
    uint256 internal constant TEAM_MINT_CHUNK = 100;
    uint256 internal constant MAX_BATCH = 250;
    uint256 internal constant OPS_PUSH_GAS = 50_000;
    /// @dev Same Agent ID NFT the existing MINT.AI vaults check. Holding one is enough.
    address public constant AGENT_ID_NFT = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    /// @notice Pool Launch Portal. Same address on BSC mainnet and testnet.
    address public constant portal = 0x000042108465206185A077Edc3F3fd2b49060000;
    uint256 public constant MAX_MINTS = 10;
    uint256 internal constant PRESALE_WINDOW = 7 days;
    address internal constant PANCAKE_V2_MAINNET = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant PANCAKE_V2_TESTNET = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    uint256 internal constant LADDER_STREAM = 7 days;
    /// @dev Smallest ladder payment that may open or top up a dividend stream.
    uint256 internal constant MIN_LADDER_STREAM = 0.01 ether;
    uint256 internal constant PRICE_TICK = 0.00001 ether;
    uint256 internal constant MAX_TICK = 1 << 20;
    uint256 internal constant ACC = 1e18;

    address public owner;
    address public opsWallet;
    address public teamWallet;
    address public router;
    address public factory;
    uint256 public presaleDeadline;

    string public tokenName;
    string public tokenSymbol;
    string public tokenMeta;
    bytes32 public salt;
    /// @dev Set in the transaction that mints the 20,000th presale card and opens the pool.
    uint256 public presaleFilledAt;
    bool public saltLocked;

    address public launchedToken;
    address public launchedPool;
    address public vault;
    bool public launched;
    bool public launching;

    uint256 public paidMinted;
    uint256 public teamMinted;
    uint256 public lastTokenId;
    uint256 public presaleEscrow;

    /// @dev Every BNB wei this contract owes: presaleEscrow + dividendLiability + pendingDividend
    ///      + streamRemaining + sideStreamRemaining + opsOwed + bidEscrow + proceedsLiability.
    uint256 public booked;

    uint256 public totalWeight;
    uint256 public accRewardPerShare;
    uint256 public dividendLiability;
    uint256 public pendingDividend;
    uint256 public streamRemaining;
    uint256 public streamRate;
    uint256 public streamEnd;
    uint256 public streamLast;
    uint256 public opsOwed;

    uint256 public totalDividendIn;
    uint256 public totalDividendPaid;
    uint256 public totalOpsPaid;

    mapping(address => uint256) public mintsUsed;
    /// @dev Presale cards minted by each address; MintAIVault vests 8,440 tokens per card from launch.
    mapping(address => uint256) public presaleCards;
    mapping(uint256 => bool) public isTeamCard;
    mapping(uint256 => uint256) public rewardDebt;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bid) public bids;
    uint256 public nextBidId;
    uint256 public bidEscrow;
    mapping(address => uint256) public proceedsOwed;
    uint256 public proceedsLiability;
    uint256 public totalMarketFees;
    /// @dev One bit per listed card id / open bid id, paged by MintAICardsLens.
    mapping(uint256 => uint256) public listedBits;
    mapping(uint256 => uint256) public openBidBits;
    /// @dev Listings per price tick, one bit per non-empty tick, one bit per non-empty tickBits word,
    ///      and a lower bound for the lowest listed tick.
    mapping(uint256 => uint256) public tickCount;
    mapping(uint256 => uint256) public tickBits;
    mapping(uint256 => uint256) public tickWordBits;
    uint256 public floorHint;
    /// @dev Listed ids per `tick << 1 | post`, where post = 1 for post-open paid cards and 0 for presale and
    ///      team cards. Newest first; 0 ends a list.
    mapping(uint256 => uint256) public tickHead;
    mapping(uint256 => uint256) public nextListed;
    mapping(uint256 => uint256) internal prevListed;
    /// @dev 1-based team ordinal => the second a paid mint unlocked it. The token vest starts then.
    mapping(uint256 => uint40) public teamUnlockAt;
    /// @dev Ladder BNB that arrived while `streamRemaining` was still paying out. The first payment
    ///      has its own 7 days. A later payment keeps that end and only raises the rate.
    uint256 public sideStreamRemaining;
    uint256 public sideStreamRate;
    uint256 public sideStreamEnd;
    uint256 public sideStreamLast;

    event PaidMint(address indexed minter, uint256 indexed tokenId, uint256 paidIndex, uint256 price);
    event TeamCardMinted(uint256 indexed tokenId, uint256 ordinal);
    event Refunded(uint256 indexed tokenId, address indexed to, uint256 amount);
    event Launched(address indexed token, address indexed pair, address indexed vault, uint256 opsShare);
    event DividendIndexed(uint256 amount, uint256 weight);
    event DividendClaimed(address indexed to, uint256 amount);
    event OpsPaid(address indexed to, uint256 amount);
    event OpsDeferred(address indexed to, uint256 amount);
    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Unlisted(uint256 indexed tokenId, address indexed seller);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 fee);
    event BidPlaced(uint256 indexed bidId, address indexed bidder, uint256 price, uint256 quantity);
    event BidCancelled(uint256 indexed bidId, address indexed bidder, uint256 refund);
    event ProceedsCredited(address indexed to, uint256 amount);
    event ProceedsWithdrawn(address indexed from, address indexed to, uint256 amount);
    event RoleUpdated(string role, address indexed previous, address indexed next);

    error ZeroAddress();
    error NotOwnerOrGuardian();
    error NotGuardian();
    error NotVault();
    error NotLaunched();
    error AlreadyLaunched();
    error PresaleClosed();
    error PresaleNotFailed();
    error PresaleFull();
    error PresaleNotSoldOut();
    error LaunchClosed();
    error SoldOut();
    error AgentIdRequired();
    error MintCapReached();
    error BadCount();
    error WrongPayment(uint256 expected, uint256 sent);
    error NotCardOwner();
    error NotTeam();
    error TeamNotUnlocked();
    error TransferLocked();
    error NothingToClaim();
    error PayFailed();
    error BadOrder();
    error BadPrice();
    error NotBidder();
    error BidFilled();
    error NothingBought();
    error OccupiedFunds(uint256 free, uint256 requested);
    error LaunchFailed();
    error SaltNotLocked();
    error BadRouter();
    error ZeroMinTokens();
    error LadderTooSmall(uint256 amount);

    modifier onlyOwnerOrGuardian() {
        if (msg.sender != owner && msg.sender != LaunchVaultAddresses.guardian()) revert NotOwnerOrGuardian();
        _;
    }

    function _lowBit(uint256 bits) internal pure returns (uint256 r) {
        while (bits & 1 == 0) {
            bits >>= 1;
            unchecked {
                ++r;
            }
        }
    }

    function _addWeight(uint256 tokenId) internal {
        _accrueStream();
        _index(0);
        rewardDebt[tokenId] = accRewardPerShare;
        totalWeight += 1;
    }

    /// @dev Spread `amount` plus any undistributed remainder over the current cards.
    function _index(uint256 amount) internal {
        uint256 pending = pendingDividend + amount;
        uint256 weight = totalWeight;
        if (pending == 0 || weight == 0) {
            pendingDividend = pending;
            return;
        }
        uint256 share = pending * ACC / weight;
        if (share == 0) {
            pendingDividend = pending;
            return;
        }
        accRewardPerShare += share;
        uint256 used = (share * weight + ACC - 1) / ACC;
        if (used > pending) used = pending;
        pendingDividend = pending - used;
        dividendLiability += used;
        emit DividendIndexed(used, weight);
    }

    function _streamDue() internal view returns (uint256 due) {
        if (streamRemaining == 0) return 0;
        if (block.timestamp >= streamEnd) return streamRemaining;
        due = (block.timestamp - streamLast) * streamRate / ACC;
        if (due > streamRemaining) due = streamRemaining;
    }

    function _sideDue() internal view returns (uint256 due) {
        if (sideStreamRemaining == 0) return 0;
        if (block.timestamp >= sideStreamEnd) return sideStreamRemaining;
        due = (block.timestamp - sideStreamLast) * sideStreamRate / ACC;
        if (due > sideStreamRemaining) due = sideStreamRemaining;
    }

    function _accrueStream() internal {
        uint256 due = _streamDue();
        uint256 side = _sideDue();
        if (due + side == 0) return;
        if (due != 0) {
            streamRemaining -= due;
            streamLast = block.timestamp;
            if (streamRemaining == 0) streamRate = 0;
        }
        if (side != 0) {
            sideStreamRemaining -= side;
            sideStreamLast = block.timestamp;
            if (sideStreamRemaining == 0) sideStreamRate = 0;
        }
        _index(due + side);
    }

    function _settleDividend(uint256 tokenId) internal returns (uint256 amount) {
        uint256 acc = accRewardPerShare;
        amount = (acc - rewardDebt[tokenId]) / ACC;
        rewardDebt[tokenId] = acc;
        dividendLiability -= amount;
        totalDividendPaid += amount;
    }

    /// @dev Moves a sold card. The seller gets price - 1% fee plus the card's dividend so far.
    function _settleSale(uint256 tokenId, address seller, address buyer, uint256 price)
        internal
        returns (uint256 toSeller)
    {
        uint256 fee = price * MARKET_FEE_BPS / BPS;
        opsOwed += fee;
        totalMarketFees += fee;
        uint256 dividend = _settleDividend(tokenId);
        _transfer(seller, buyer, tokenId);
        toSeller = price - fee + dividend;
        emit Sold(tokenId, seller, buyer, price, fee);
    }

    /// @dev Transfers are locked before launch. On a plain transfer the card's dividend so far is credited to
    ///      the sender as withdrawable proceeds. Burns (presale refunds, floor buys) remove the card's weight;
    ///      callers settle the dividend first.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address from) {
        address prev = _ownerOf(tokenId);
        if (prev != address(0) && to != address(0)) {
            if (!launched) revert TransferLocked();
            _accrueStream();
            uint256 earned = _settleDividend(tokenId);
            if (earned != 0) {
                proceedsOwed[prev] += earned;
                proceedsLiability += earned;
                emit ProceedsCredited(prev, earned);
            }
            if (vault != address(0)) IMintAIVault(vault).moveCardVest(to, tokenId);
        } else if (prev != address(0)) {
            totalWeight -= 1;
        }
        from = super._update(to, tokenId, auth);
        if (listings[tokenId].seller != address(0)) _clearListing(tokenId);
    }

    function _clearListing(uint256 id) internal {
        uint256 tick = listings[id].price / PRICE_TICK;
        delete listings[id];
        listedBits[id >> 8] &= ~(1 << (id & 255));
        uint256 next = nextListed[id];
        uint256 prev = prevListed[id];
        if (prev == 0) tickHead[tick << 1 | (id > FIRST_BATCH && !isTeamCard[id] ? 1 : 0)] = next;
        else nextListed[prev] = next;
        if (next != 0) prevListed[next] = prev;
        delete nextListed[id];
        delete prevListed[id];
        if (--tickCount[tick] == 0) {
            uint256 w = tick >> 8;
            uint256 bits = tickBits[w] & ~(1 << (tick & 255));
            tickBits[w] = bits;
            if (bits == 0) tickWordBits[w >> 8] &= ~(1 << (w & 255));
        }
    }

    function _pushOps() internal {
        uint256 amount = opsOwed;
        if (amount == 0) return;
        address to = opsWallet;
        opsOwed = 0;
        booked -= amount;
        uint256 gasCap = OPS_PUSH_GAS;
        bool ok;
        assembly {
            ok := call(gasCap, to, amount, 0, 0, 0, 0)
        }
        if (ok) {
            totalOpsPaid += amount;
            emit OpsPaid(to, amount);
        } else {
            opsOwed = amount;
            booked += amount;
            emit OpsDeferred(to, amount);
        }
    }

    function _sendBnb(address to, uint256 amount) internal {
        booked -= amount;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert PayFailed();
    }

    function _payOrCredit(address to, uint256 amount) internal {
        if (amount == 0) return;
        booked -= amount;
        uint256 gasCap = OPS_PUSH_GAS;
        bool ok;
        assembly {
            ok := call(gasCap, to, amount, 0, 0, 0, 0)
        }
        if (!ok) {
            booked += amount;
            proceedsOwed[to] += amount;
            proceedsLiability += amount;
            emit ProceedsCredited(to, amount);
        }
    }
}

// src/MintAICards.sol

/**
 * @title MintAICards
 * @notice MINT.AI cards. The NFT collection name and symbol are both MINT.AI. Sells the presale, launches the token through Flap Pool Launch, then keeps
 *         selling cards at a flat price, splits BNB dividends, runs the card market and spends
 *         the floor fund on the cheapest listed cards.
 *
 * Cards
 *   - 777,777 cards: 738,889 paid and 38,888 team cards. Every 19 paid cards unlock 1 team card.
 *   - Presale cards (the first 20,000 paid cards) cost 0.00245 BNB. Every later paid card costs 0.0049 BNB.
 *   - Buyers must hold an Agent ID NFT (balanceOf > 0 on the shared Agent ID contract). Each address can
 *     mint 10 paid cards in its lifetime. Burning does not restore the quota. The card market does not use it.
 *
 * Presale
 *   - BNB is escrowed here. Cards cannot be transferred before launch.
 *   - The sale runs for 7 days from creation. If 20,000 are not sold by then, every holder can burn
 *     for a full refund. The mint that sells the 20,000th card launches in that same transaction.
 *     A sold-out presale cannot be refunded.
 *   - Launch sends 36.75 BNB + 124,672,000 tokens into the pool (LP burned),
 *     the vault receives the other 653,105,777 tokens, and 12.25 BNB (25% of the presale) goes to the ops wallet.
 *     A failed presale still refunds the full 0.00245; the 25% is taken only when launch succeeds.
 *
 * Tokens (MintAIVault holds the schedules; all vest linearly over 5 days and stay with the receiving address)
 *   - Each presale card: 8,440 tokens from the vault reserve, vesting from launch.
 *   - Each team card: 8,440 tokens from the vault reserve, vesting from the second that paid mint unlocked it.
 *   - Each post-open paid card: 25% of the payment to ops; 75% buys tokens on the pool at the current price.
 *     10% of what is bought is burned, 90% vests to the minter from the mint. The amount is fixed at the mint.
 *
 * Dividends
 *   - 50% of the vault's tax revenue and all ladder proceeds (streamed over 7 days) are split equally per card.
 *   - New cards do not share revenue that arrived before them. On any transfer the seller keeps what the
 *     card earned so far.
 *
 * Floor fund
 *   - 30% of the vault's tax revenue, held and spent by MintAIVault through floorBuy (see MintAIVault).
 *     Listings are kept in one list per price tick and card class so the vault can walk them cheapest first.
 *
 * Market
 *   - Sell orders without escrow and buy orders with escrow. 1% of every fill goes to the ops wallet.
 *     Ask prices are multiples of 0.00001 BNB below 10.48576 BNB.
 */
contract MintAICards is MintAICardsBase {
    struct InitParams {
        address owner;
        address opsWallet;
        address teamWallet;
        address router;
        string tokenName;
        string tokenSymbol;
        string tokenMeta;
        bytes32 salt;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Called by the launcher factory while it creates this proxy. `vaultFactory_` is the pl-v1 factory.
    function initialize(InitParams calldata init, address vaultFactory_) external payable initializer {
        __ERC721_init("MINT.AI", "MINT.AI");
        __ReentrancyGuard_init();
        if (
            init.owner == address(0) || init.opsWallet == address(0) || init.teamWallet == address(0)
                || vaultFactory_ == address(0)
        ) revert ZeroAddress();
        address pancake = block.chainid == 56 ? PANCAKE_V2_MAINNET : PANCAKE_V2_TESTNET;
        if (init.router != pancake) revert BadRouter();
        owner = init.owner;
        opsWallet = init.opsWallet;
        teamWallet = init.teamWallet;
        router = pancake;
        presaleDeadline = block.timestamp + PRESALE_WINDOW;
        tokenName = init.tokenName;
        tokenSymbol = init.tokenSymbol;
        tokenMeta = init.tokenMeta;
        salt = init.salt;
        factory = vaultFactory_;
        _screen(init.tokenName, init.tokenSymbol);
        uint256 fee = IDirectLaunchPortal(portal).SALT_LOCK_FEE();
        if (msg.value != fee) revert WrongPayment(fee, msg.value);
        IDirectLaunchPortal(portal).lockSalt{value: fee}(init.salt, 0);
        saltLocked = true;
    }

    /// @notice Feed JSON read by the Pool Launch Portal at creation. `v` is the only number.
    ///         Only the token name and symbol are escaped. Titles and summaries are constants.
    function description() external view returns (string memory) {
        return string.concat(
            '{"v":1,"name":"',
            _jsonEscape(tokenName),
            '","symbol":"',
            _jsonEscape(tokenSymbol),
            '","quoteToken":"0x0000000000000000000000000000000000000000","targetRaise":"',
            Strings.toString(FIRST_BATCH * PRESALE_PRICE),
            '","poolTokenRatio":"',
            Strings.toString(MintAIParams.POOL_TOKEN * 1e18 / MintAIParams.TOTAL_SUPPLY),
            '","titleZh":"MINT.AI","titleEn":"MINT.AI","summaryZh":"',
            "\u9884\u552e 20,000 \u5f20\uff0c\u6bcf\u5f20 0.00245 BNB\uff0c7 \u5929\u6ca1\u5356\u6ee1\u53ef\u5168\u989d\u9000\u6b3e\u3002\u5f00\u76d8\u540e\u6bcf\u5f20 0.0049 BNB\u3002\u6bcf\u7b14\u94f8\u9020\u6b3e 25% \u7ed9\u8fd0\u8425\u3002\u9884\u552e\u5361\u548c\u56e2\u961f\u5361\u5404\u5f97 8,440 \u679a\u3002\u7a0e 2%\uff0c\u6309\u6301\u5361\u4eba 50%\u3001\u5730\u677f 30%\u3001\u8fd0\u8425 20% \u5206\u914d\u3002\u5e02\u573a\u6210\u4ea4\u8d39 1%\u3002",
            '","summaryEn":"',
            "Presale: 20,000 cards at 0.00245 BNB. Unsold after 7 days can be fully refunded. After launch, 0.0049 BNB per card. 25% of each mint payment goes to operations. Each presale card and team card receives 8,440 tokens. The 2% tax splits 50% to holders, 30% to the floor, and 20% to operations. Market fee is 1%.",
            '"}'
        );
    }

    // ---------------------------------------------------------------- mint

    /// @notice Buy `count` paid cards for exactly `priceOf(next) * count`. After launch `minTokens` is the least
    ///         number of tokens that must vest to the caller from this mint; it is ignored during the presale.
    function mint(uint256 count, uint256 minTokens) external payable nonReentrant returns (uint256 lastId) {
        if (count == 0 || count > MAX_MINT_PER_TX) revert BadCount();
        if (IERC721(AGENT_ID_NFT).balanceOf(msg.sender) == 0) revert AgentIdRequired();
        uint256 used = mintsUsed[msg.sender] + count;
        if (used > MAX_MINTS) revert MintCapReached();
        mintsUsed[msg.sender] = used;
        uint256 paid = paidMinted;
        bool live = launched;
        if (!live) {
            if (block.timestamp > presaleDeadline) revert PresaleClosed();
            if (paid + count > FIRST_BATCH) revert PresaleFull();
            if (paid + count == FIRST_BATCH && !saltLocked) revert SaltNotLocked();
        } else if (paid + count > PAID_CAP) {
            revert SoldOut();
        }
        uint256 price = live ? MINT_PRICE : PRESALE_PRICE;
        uint256 total = price * count;
        if (msg.value != total) revert WrongPayment(total, msg.value);
        // Split tax that is already in the vault before these new cards take weight.
        if (live) _syncVault();

        for (uint256 i; i < count; ++i) {
            uint256 index = paid + i + 1;
            lastId = ++lastTokenId;
            _mint(msg.sender, lastId);
            _addWeight(lastId);
            if (index % UNLOCK_EVERY == 0) teamUnlockAt[index / UNLOCK_EVERY] = uint40(block.timestamp);
            emit PaidMint(msg.sender, lastId, index, price);
        }
        paidMinted = paid + count;

        if (!live) {
            presaleEscrow += total;
            booked += total;
            if (presaleCards[msg.sender] == 0) IMintAIFactory(factory).notePresaleBuyer(msg.sender);
            presaleCards[msg.sender] += count;
            if (paidMinted == FIRST_BATCH) {
                presaleFilledAt = block.timestamp;
                _openPool();
            }
        } else {
            if (minTokens == 0) revert ZeroMinTokens();
            uint256 ops = total * OPS_BPS / BPS;
            opsOwed += ops;
            booked += ops;
            IMintAIVault(vault).buyForMint{value: total - ops}(msg.sender, lastId + 1 - count, count, minTokens);
            _pushOps();
        }
    }

    /// @notice Mint `count` unlocked team cards to `to`. Only the team wallet, only after launch, at most 100
    ///         cards per call. Each card vests 8,440 from the second its ordinal was unlocked. Call again for
    ///         another wallet or another batch.
    function mintTeam(address to, uint256 count) external nonReentrant {
        if (msg.sender != teamWallet) revert NotTeam();
        if (!launched) revert NotLaunched();
        if (to == address(0)) revert ZeroAddress();
        if (count == 0 || count > TEAM_MINT_CHUNK) revert BadCount();
        uint256 cursor = teamMinted;
        if (cursor + count > paidMinted / UNLOCK_EVERY) revert TeamNotUnlocked();
        // Split tax that is already in the vault before these team cards take weight.
        _syncVault();
        for (uint256 i; i < count; ++i) {
            uint256 id = ++lastTokenId;
            isTeamCard[id] = true;
            _mint(to, id);
            _addWeight(id);
            emit TeamCardMinted(id, cursor + i);
        }
        teamMinted = cursor + count;
        IMintAIVault(vault).addTeamGrants(to, cursor, count);
    }

    /// @notice Burn presale cards for a full refund once the presale window ended without selling out.
    function refund(uint256[] calldata tokenIds) external nonReentrant returns (uint256 amount) {
        if (launched || paidMinted >= FIRST_BATCH || block.timestamp <= presaleDeadline) revert PresaleNotFailed();
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH) revert BadOrder();
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            if (_ownerOf(id) != msg.sender) revert NotCardOwner();
            _burn(id);
            amount += PRESALE_PRICE;
            emit Refunded(id, msg.sender, PRESALE_PRICE);
        }
        presaleEscrow -= amount;
        _sendBnb(msg.sender, amount);
    }

    // ---------------------------------------------------------------- launch

    /// @dev Opens the pool in the mint that sells the 20,000th presale card. The vault launcher is the project owner.
    function _openPool() private {
        if (launched) revert AlreadyLaunched();
        if (paidMinted < FIRST_BATCH) revert PresaleNotSoldOut();
        if (!saltLocked) revert SaltNotLocked();
        launching = true;
        (address token_, address pair_) = IDirectLaunchPortal(portal).launchTaxTokenV2{value: MintAIParams.POOL_QUOTE}(
            _launchParams(), Distribution(DistributionTarget.VAULT, address(0), uint128(MintAIParams.RESERVE), ""),
            CreatorBuyParams(0, "")
        );
        launching = false;
        if (uint16(uint160(token_)) != 0x7777) revert LaunchFailed();
        address vault_ = IMintAIFactory(factory).vaultOf(token_);
        if (vault_ == address(0) || token_ == address(0) || pair_ == address(0)) revert LaunchFailed();
        launchedToken = token_;
        launchedPool = pair_;
        vault = vault_;
        launched = true;

        uint256 escrow = presaleEscrow;
        uint256 opsShare = escrow - MintAIParams.POOL_QUOTE;
        presaleEscrow = 0;
        booked -= MintAIParams.POOL_QUOTE;
        opsOwed += opsShare;
        IMintAIVault(vault_).onLaunched(pair_, router, owner);
        emit Launched(token_, pair_, vault_, opsShare);
        _pushOps();
    }

    // ---------------------------------------------------------------- dividends

    /// @notice Claim the BNB dividend of the given cards.
    function claim(uint256[] calldata tokenIds) external nonReentrant returns (uint256 amount) {
        _syncVault();
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH) revert BadOrder();
        _accrueStream();
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            if (_ownerOf(id) != msg.sender) revert NotCardOwner();
            amount += _settleDividend(id);
        }
        if (amount == 0) revert NothingToClaim();
        _sendBnb(msg.sender, amount);
        emit DividendClaimed(msg.sender, amount);
    }

    /// @notice Vault hook: card dividend now, ladder proceeds streamed over 7 days, and the ops share.
    ///         An open main stream keeps its rate and end. The first side payment starts its own 7 days.
    ///         A later side payment keeps that end and raises the rate so the old remainder is not spread out again.
    ///         A ladder payment under 0.01 BNB is rejected.
    function onVaultRevenue(uint256 dividendNow, uint256 dividendStream, uint256 ops) external payable {
        if (msg.sender != vault) revert NotVault();
        uint256 total = dividendNow + dividendStream + ops;
        if (msg.value != total) revert WrongPayment(total, msg.value);
        if (dividendStream != 0 && dividendStream < MIN_LADDER_STREAM) revert LadderTooSmall(dividendStream);
        booked += total;
        opsOwed += ops;
        totalDividendIn += dividendNow + dividendStream;
        _accrueStream();
        if (dividendStream != 0) {
            if (streamRemaining == 0) {
                streamRemaining = dividendStream;
                streamRate = dividendStream * ACC / LADDER_STREAM;
                streamEnd = block.timestamp + LADDER_STREAM;
                streamLast = block.timestamp;
            } else if (sideStreamRemaining == 0) {
                sideStreamRemaining = dividendStream;
                sideStreamRate = dividendStream * ACC / LADDER_STREAM;
                sideStreamEnd = block.timestamp + LADDER_STREAM;
                sideStreamLast = block.timestamp;
            } else {
                sideStreamRemaining += dividendStream;
                uint256 span = sideStreamEnd > block.timestamp ? sideStreamEnd - block.timestamp : 1;
                uint256 faster = sideStreamRemaining * ACC / span;
                if (faster > sideStreamRate) sideStreamRate = faster;
                sideStreamLast = block.timestamp;
            }
        }
        _index(dividendNow);
    }

    /// @notice Release streamed dividends and retry any deferred ops payment.
    function poke() external nonReentrant {
        _accrueStream();
        _pushOps();
    }

    // ---------------------------------------------------------------- floor fund

    /// @notice Vault-only: buy listed card `id` at its exact ask with the floor fund sent along. The seller gets
    ///         the full price plus the card's dividend so far, and the card is burned.
    function floorBuy(uint256 id) external payable nonReentrant {
        if (msg.sender != vault) revert NotVault();
        Listing memory l = listings[id];
        if (l.seller == address(0) || l.price != msg.value) revert BadPrice();
        booked += msg.value;
        _accrueStream();
        uint256 dividend = _settleDividend(id);
        _burn(id);
        _payOrCredit(l.seller, msg.value + dividend);
    }

    // ---------------------------------------------------------------- market
    // Bodies live on MintAICardMarket, deployed with the vault factory. Delegatecall keeps the proxy storage.
    // Argument names are omitted here. `_toMarket` forwards the entire calldata, and the market module reads it.

    function list(uint256[] calldata, uint256[] calldata) external {
        _toMarket();
    }

    function unlist(uint256[] calldata) external {
        _toMarket();
    }

    function buy(uint256[] calldata, uint256[] calldata) external payable returns (uint256) {
        _syncVault();
        _toMarket();
    }

    function placeBid(uint256, uint256) external payable returns (uint256) {
        _toMarket();
    }

    function cancelBids(uint256[] calldata) external returns (uint256) {
        _toMarket();
    }

    function sellToBid(uint256, uint256[] calldata) external returns (uint256) {
        _syncVault();
        _toMarket();
    }

    function withdrawProceeds(address) external returns (uint256) {
        _toMarket();
    }

    /// @dev Split BNB already sitting in the vault. No-op before launch. Does not pull the tax processor.
    function _syncVault() private {
        if (vault == address(0)) return;
        IMintAIVault(vault).sync();
    }

    /// @dev Forwards the current call to the market logic deployed by the vault factory.
    function _toMarket() private {
        address logic = IMintAIFactory(factory).marketLogic();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // ---------------------------------------------------------------- views

    /// @notice Price of the `paidIndex`-th paid card (1-based).
    function priceOf(uint256 paidIndex) external pure returns (uint256) {
        return paidIndex <= FIRST_BATCH ? PRESALE_PRICE : MINT_PRICE;
    }

    function teamUnlocked() external view returns (uint256) {
        return paidMinted / UNLOCK_EVERY;
    }

    function presaleFailed() public view returns (bool) {
        return !launched && block.timestamp > presaleDeadline && paidMinted < FIRST_BATCH;
    }

    function pendingDividendOf(uint256 tokenId) external view returns (uint256) {
        if (_ownerOf(tokenId) == address(0)) return 0;
        uint256 acc = accRewardPerShare;
        uint256 weight = totalWeight;
        if (weight != 0) {
            uint256 streamed = _streamDue() + _sideDue();
            acc += (pendingDividend + streamed) * ACC / weight;
        }
        return (acc - rewardDebt[tokenId]) / ACC;
    }

    // ---------------------------------------------------------------- roles

    function setOpsWallet(address next) external onlyOwnerOrGuardian {
        if (next == address(0)) revert ZeroAddress();
        emit RoleUpdated("ops", opsWallet, next);
        opsWallet = next;
    }

    function setTeamWallet(address next) external onlyOwnerOrGuardian {
        if (next == address(0)) revert ZeroAddress();
        emit RoleUpdated("team", teamWallet, next);
        teamWallet = next;
    }

    function transferOwnership(address next) external onlyOwnerOrGuardian {
        if (next == address(0)) revert ZeroAddress();
        emit RoleUpdated("owner", owner, next);
        owner = next;
    }

    /// @notice Guardian may only take BNB nobody is owed (forced sends).
    function emergencyWithdrawNative(address to, uint256 amount) external nonReentrant {
        if (msg.sender != LaunchVaultAddresses.guardian()) revert NotGuardian();
        if (to == address(0)) revert ZeroAddress();
        uint256 bal = address(this).balance;
        uint256 free = bal > booked ? bal - booked : 0;
        if (amount > free) revert OccupiedFunds(free, amount);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert PayFailed();
    }

    // ---------------------------------------------------------------- internals

    function _launchParams() private view returns (CreateTaxTokenParams memory p) {
        FeeConfig[] memory fees = new FeeConfig[](1);
        fees[0] = FeeConfig(FeeSlotType.VAULT, 10_000, abi.encode(FeeConfigVault(factory, "")));
        p.name = tokenName;
        p.symbol = tokenSymbol;
        p.meta = tokenMeta;
        p.totalSupply = MintAIParams.TOTAL_SUPPLY;
        p.salt = salt;
        p.quoteToken = address(0);
        p.dexId = 0;
        p.poolQuote = MintAIParams.POOL_QUOTE;
        p.poolToken = MintAIParams.POOL_TOKEN;
        p.buyTaxRate = MintAIParams.TAX_BPS;
        p.sellTaxRate = MintAIParams.TAX_BPS;
        p.taxDuration = MintAIParams.TAX_DURATION;
        p.antiFarmerDuration = 0;
        p.feeConfigs = fees;
        p.exemptAddrs = new address[](0);
        (bytes32 extensionID, bytes32 creatorWord) = _creatorExtension();
        p.extensionID = extensionID;
        bytes memory extensionData = new bytes(32);
        assembly {
            mstore(add(extensionData, 32), creatorWord)
        }
        p.extensionData = extensionData;
    }

    /// @notice Lowest non-empty price tick at or above `h`, or MAX_TICK when there is none. Start from floorHint
    ///         for the floor. At most 17 reads: the start word, then the 16 summary words.
    function nextTick(uint256 h) external view returns (uint256) {
        if (h >= MAX_TICK) return MAX_TICK;
        uint256 word = h >> 8;
        uint256 bits = tickBits[word] & (type(uint256).max << (h & 255));
        if (bits != 0) return (word << 8) | _lowBit(bits);
        if (++word >= MAX_TICK >> 8) return MAX_TICK;
        uint256 s = word >> 8;
        bits = tickWordBits[s] & (type(uint256).max << (word & 255));
        while (bits == 0) {
            if (++s >= MAX_TICK >> 16) return MAX_TICK;
            bits = tickWordBits[s];
        }
        word = (s << 8) | _lowBit(bits);
        return (word << 8) | _lowBit(tickBits[word]);
    }

    /// @dev JSON string escape for the two user-supplied feed fields.
    function _jsonEscape(string memory s) private pure returns (string memory) {
        bytes memory raw = bytes(s);
        uint256 extra;
        for (uint256 i; i < raw.length; ++i) {
            bytes1 c = raw[i];
            if (c == '"' || c == "\\" || c == "\n" || c == "\r" || c == "\t") extra += 1;
        }
        if (extra == 0) return s;
        bytes memory out = new bytes(raw.length + extra);
        uint256 j;
        for (uint256 i; i < raw.length; ++i) {
            bytes1 c = raw[i];
            if (c == '"') {
                out[j++] = "\\";
                out[j++] = '"';
            } else if (c == "\\") {
                out[j++] = "\\";
                out[j++] = "\\";
            } else if (c == "\n") {
                out[j++] = "\\";
                out[j++] = "n";
            } else if (c == "\r") {
                out[j++] = "\\";
                out[j++] = "r";
            } else if (c == "\t") {
                out[j++] = "\\";
                out[j++] = "t";
            } else {
                out[j++] = c;
            }
        }
        return string(out);
    }

    /// @dev Flap anti-scam module: reject a flagged token name or symbol.
    function _screen(string calldata name, string calldata symbol) private view {
        IMintAIFactory(factory).rejectScam(name, symbol);
    }

    function _creatorExtension() private view returns (bytes32 extensionID, bytes32 creatorWord) {
        (extensionID, creatorWord) = IMintAIFactory(factory).creatorExtension();
    }
}

// src/MintAIVaultFactory.sol

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
        policies[1] = FactoryPolicy("totalSupply", "eq", abi.encode(MintAIParams.TOTAL_SUPPLY), "777,777,777 tokens");
        policies[2] = FactoryPolicy("poolToken", "eq", abi.encode(MintAIParams.POOL_TOKEN), "124,672,000 tokens in the pool");
        policies[3] = FactoryPolicy("poolQuote", "eq", abi.encode(MintAIParams.POOL_QUOTE), "36.75 BNB, native quote only");
        policies[4] = FactoryPolicy("buyTaxRate", "eq", abi.encode(uint256(MintAIParams.TAX_BPS)), "2% buy and sell tax");
        policies[5] = FactoryPolicy("feeConfigs", "eq", "", "Single VAULT slot of 10000 bps pointing to this factory");
    }

    function _validate(CreateTaxTokenParams memory p, Distribution memory d) private view {
        if (p.quoteToken != address(0)) revert BadLaunch("quote");
        if (p.totalSupply != MintAIParams.TOTAL_SUPPLY) revert BadLaunch("supply");
        if (p.poolToken != MintAIParams.POOL_TOKEN || p.poolQuote != MintAIParams.POOL_QUOTE) revert BadLaunch("pool");
        if (p.buyTaxRate != MintAIParams.TAX_BPS || p.sellTaxRate != MintAIParams.TAX_BPS) revert BadLaunch("tax");
        if (p.taxDuration != MintAIParams.TAX_DURATION) revert BadLaunch("taxDuration");
        if (p.creatorBuyQuote != 0) revert BadLaunch("creatorBuy");
        if (p.commissionReceiver != address(0)) revert BadLaunch("commission");
        if (p.feeConfigs.length != 1) revert BadLaunch("slots");
        FeeConfig memory f = p.feeConfigs[0];
        if (f.feeType != FeeSlotType.VAULT || f.bps != 10_000) revert BadLaunch("vault slot");
        FeeConfigVault memory v = abi.decode(f.configData, (FeeConfigVault));
        if (v.vaultFactory != address(this) || v.vaultData.length != 0) revert BadLaunch("vault data");
        if (d.target != DistributionTarget.VAULT || d.amount != MintAIParams.RESERVE) revert BadLaunch("distribution");
    }
}

// src/MintAILauncherFactory.sol

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
