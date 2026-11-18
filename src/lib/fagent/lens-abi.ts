// Generated from user-uploaded fagent-pool-vault-duel.zip Solidity 0.8.24.
export const lensAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "cards",
        "type": "address"
      }
    ],
    "name": "floor",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "price",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "listed",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "cards",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "cursor",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "limit",
        "type": "uint256"
      }
    ],
    "name": "getActiveBids",
    "outputs": [
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "bidId",
            "type": "uint256"
          },
          {
            "internalType": "address",
            "name": "bidder",
            "type": "address"
          },
          {
            "internalType": "uint96",
            "name": "price",
            "type": "uint96"
          },
          {
            "internalType": "uint32",
            "name": "remaining",
            "type": "uint32"
          }
        ],
        "internalType": "struct MintAICardsLens.BidView[]",
        "name": "orders",
        "type": "tuple[]"
      },
      {
        "internalType": "uint256",
        "name": "next",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "end",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "cards",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "cursor",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "limit",
        "type": "uint256"
      }
    ],
    "name": "getActiveListings",
    "outputs": [
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "tokenId",
            "type": "uint256"
          },
          {
            "internalType": "address",
            "name": "seller",
            "type": "address"
          },
          {
            "internalType": "uint96",
            "name": "price",
            "type": "uint96"
          }
        ],
        "internalType": "struct MintAICardsLens.ListingView[]",
        "name": "orders",
        "type": "tuple[]"
      },
      {
        "internalType": "uint256",
        "name": "next",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "end",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "cards",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "count",
        "type": "uint256"
      }
    ],
    "name": "quoteMint",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "total",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "tokens",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const;
