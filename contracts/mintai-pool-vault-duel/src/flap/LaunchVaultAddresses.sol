// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
