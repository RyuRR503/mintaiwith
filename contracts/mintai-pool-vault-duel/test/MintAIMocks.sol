// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CreateTaxTokenParams, Distribution, CreatorBuyParams, FeeConfigVault} from "../src/flap/IDirectPoolLaunch.sol";

interface IFactoryLaunch {
    function newVault(address token, address creator, uint8 launchKind, bytes calldata launchParams)
        external
        returns (address vault);
}

interface IStrategyLaunch {
    function initializeDistribution(address token, uint256 amount, bytes calldata configData, bytes32 salt) external;
}

contract MockTaxToken is ERC20 {
    constructor() ERC20("MINT.AI", "MINT.AI") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockWBNB {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/// @dev Pool stand-in. Quote reserve tracks the WBNB balance after sync; the token reserve stays put,
///      because the pool's tokens are not actually transferred in these tests.
contract MockPair {
    address public token0;
    address public token1;
    uint112 public r0;
    uint112 public r1;
    uint32 public blockTs;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    address public wbnb;
    bool public tokenIs0;

    constructor(address token, address w, uint256 quoteAmt, uint256 tokenAmt) {
        wbnb = w;
        if (token < w) {
            token0 = token;
            token1 = w;
            r0 = uint112(tokenAmt);
            r1 = uint112(quoteAmt);
            tokenIs0 = true;
        } else {
            token0 = w;
            token1 = token;
            r0 = uint112(quoteAmt);
            r1 = uint112(tokenAmt);
        }
        blockTs = uint32(block.timestamp);
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (r0, r1, blockTs);
    }

    function setQuote(uint256 quoteAmt) external {
        if (tokenIs0) r1 = uint112(quoteAmt);
        else r0 = uint112(quoteAmt);
    }

    function sync() external {
        uint256 q = MockWBNB(wbnb).balanceOf(address(this));
        uint32 nowTs = uint32(block.timestamp);
        if (nowTs > blockTs && r0 != 0 && r1 != 0) {
            uint32 dt = nowTs - blockTs;
            price0CumulativeLast += ((uint256(r1) << 112) / r0) * dt;
            price1CumulativeLast += ((uint256(r0) << 112) / r1) * dt;
        }
        if (tokenIs0) r1 = uint112(q);
        else r0 = uint112(q);
        blockTs = nowTs;
    }
}

contract MockDock {
    mapping(address => mapping(address => uint256)) public balanceOf;

    function deposit(address token, uint256 amount) external {
        require(ERC20(token).transferFrom(msg.sender, address(this), amount), "dock in");
        balanceOf[token][msg.sender] += amount;
    }

    function withdraw(address token, uint256 amount, address to) external {
        balanceOf[token][msg.sender] -= amount;
        require(ERC20(token).transfer(to, amount), "dock out");
    }
}

/// @dev Fixed-rate swap stand-in. `rate` is tokens per 1 BNB before the 2% buy tax; it starts at the
///      opening price (124,672,000 / 36.75).
contract MockRouter {
    address public immutable WETH_;
    uint256 public rate = uint256(124_672_000 ether) * 1e18 / 36.75 ether;
    uint256 public constant BUY_TAX_BPS = 200;

    constructor(address w) {
        WETH_ = w;
    }

    function WETH() external view returns (address) {
        return WETH_;
    }

    function setRate(uint256 r) external {
        rate = r;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata) external view returns (uint256[] memory out) {
        out = new uint256[](2);
        out[0] = amountIn;
        out[1] = amountIn * rate / 1 ether;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256
    ) external payable {
        uint256 out = msg.value * rate / 1 ether;
        out -= out * BUY_TAX_BPS / 10_000;
        require(out >= amountOutMin, "min out");
        MockTaxToken(path[1]).mint(to, out);
    }
}

/// @dev Stands in for the Flap portal at the chain-97 hub address. Etch its runtime there.
contract MockPortal {
    address public immutable wbnb;
    bytes32 internal immutable tokenSalt;

    constructor(address w) {
        wbnb = w;
        tokenSalt = _findSalt();
    }

    function SALT_LOCK_FEE() external pure returns (uint256) {
        return 0.01 ether;
    }

    bytes32 public lastExtensionID;
    bytes public lastExtensionData;

    function lockSalt(bytes32, uint8) external payable {}

    function launchTaxTokenV2(CreateTaxTokenParams calldata p, Distribution calldata d, CreatorBuyParams calldata)
        external
        payable
        returns (address token, address pool)
    {
        require(msg.value == p.poolQuote, "quote");
        lastExtensionID = p.extensionID;
        lastExtensionData = p.extensionData;
        FeeConfigVault memory cfg = abi.decode(p.feeConfigs[0].configData, (FeeConfigVault));
        MockTaxToken t = _deployToken();
        t.mint(address(this), p.totalSupply);
        address vaultAddr = IFactoryLaunch(cfg.vaultFactory).newVault(address(t), msg.sender, 0, abi.encode(p, d));
        t.approve(vaultAddr, d.amount);
        IStrategyLaunch(vaultAddr).initializeDistribution(address(t), d.amount, d.configData, p.salt);
        pool = address(new MockPair(address(t), wbnb, p.poolQuote, p.poolToken));
        MockWBNB(wbnb).mint(pool, p.poolQuote);
        token = address(t);
    }

    /// @dev The cards contract accepts a launch only when the token address ends in 7777.
    function _deployToken() internal returns (MockTaxToken) {
        return new MockTaxToken{salt: tokenSalt}();
    }

    function _findSalt() internal pure returns (bytes32) {
        bytes32 initHash = keccak256(type(MockTaxToken).creationCode);
        address hub = 0x000042108465206185A077Edc3F3fd2b49060000;
        for (uint256 i = 1; i < 5_000_000; ++i) {
            bytes32 salt = bytes32(i);
            address predicted = address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), hub, salt, initHash))))
            );
            if (uint16(uint160(predicted)) == 0x7777) return salt;
        }
        revert("no 7777");
    }
}

/// @dev Stands in for Flap's anti-scam module. Etch the runtime at the module address. Storage starts empty, so
///      nothing is flagged until `setFlagged` or `setSymbolFlagged`.
contract MockAntiScam {
    bool public nameFlagged;
    bool public symbolFlagged;

    function setFlagged(bool value) external {
        nameFlagged = value;
        symbolFlagged = value;
    }

    function setSymbolFlagged(bool value) external {
        symbolFlagged = value;
    }

    function isScamWord(string calldata, string calldata) external view returns (bool, bool) {
        return (nameFlagged, symbolFlagged);
    }
}

contract AgentIdStub {
    mapping(address => uint256) public balanceOf;

    function set(address who, uint256 bal) external {
        balanceOf[who] = bal;
    }
}

contract RevertingReceiver {
    receive() external payable {
        revert("no");
    }
}

/// @dev Etched at the Flap Trigger Service address. Storage starts empty, so the defaults live in code.
contract MockTrigger {
    uint256 public constant DEFAULT_FEE = 0.0002 ether;
    uint256 public constant CALLBACK_GAS = 2_000_000;
    uint256 public feeOverride;
    bool public broken;
    uint256 public count;
    mapping(uint256 => address) public requester;
    mapping(uint256 => uint256) public executeAfter;

    function getFee() public view returns (uint256) {
        require(!broken, "broken");
        return feeOverride == 0 ? DEFAULT_FEE : feeOverride;
    }

    function setFee(uint256 fee) external {
        feeOverride = fee;
    }

    function setBroken(bool b) external {
        broken = b;
    }

    function requestTrigger(uint64 when) external payable returns (uint256 id) {
        require(msg.value == getFee(), "fee");
        id = ++count;
        requester[id] = msg.sender;
        executeAfter[id] = when;
    }

    /// @dev Calls back like the live service: after executeAfter, with at most CALLBACK_GAS.
    function fire(uint256 id) external returns (bool ok, uint256 used) {
        require(requester[id] != address(0) && block.timestamp >= executeAfter[id], "not due");
        uint256 before = gasleft();
        (ok,) = requester[id].call{gas: CALLBACK_GAS}(abi.encodeWithSignature("trigger(uint256)", id));
        used = before - gasleft();
    }
}

contract GasBombReceiver {
    uint256 public sink;

    receive() external payable {
        while (true) {
            sink++;
        }
    }
}

contract ReturnBombReceiver {
    receive() external payable {
        assembly {
            revert(0, 100000)
        }
    }
}

interface ICardsReenter {
    function claim(uint256[] calldata tokenIds) external returns (uint256);
    function poke() external;
}

contract ReentrantReceiver {
    ICardsReenter public cards;
    uint256 public attempts;
    uint256 public successes;

    function setCards(address c) external {
        cards = ICardsReenter(c);
    }

    receive() external payable {
        attempts++;
        if (address(cards) == address(0)) return;
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        try cards.claim(ids) {
            successes++;
        } catch {}
        try cards.poke() {
            successes++;
        } catch {}
    }
}
