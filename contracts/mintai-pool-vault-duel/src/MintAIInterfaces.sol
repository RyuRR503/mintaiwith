// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
