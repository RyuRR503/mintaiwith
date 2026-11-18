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
