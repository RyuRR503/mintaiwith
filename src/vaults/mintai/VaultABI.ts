import { parseAbi } from "viem";

export const vaultAbi = parseAbi([
  "function TOTAL_CARDS() view returns (uint256)",
  "function userMints() view returns (uint256)",
  "function teamMinted() view returns (uint256)",
  "function totalWeight() view returns (uint256)",
  "function mintPrice() view returns (uint256)",
  "function batchOpenedAt() view returns (uint256)",
  "function STALL_RELEASE() view returns (uint256)",
  "function undistributedTax() view returns (uint256)",
  "function totalTaxReceived() view returns (uint256)",
  "function totalDividendPaid() view returns (uint256)",
  "function dividendLiability() view returns (uint256)",
  "function totalMarketFees() view returns (uint256)",
  "function bidEscrow() view returns (uint256)",
  "function nextBidId() view returns (uint256)",
  "function projectToken() view returns (address)",
  "function getActiveListings(uint256,uint256) view returns (uint256[],(address,uint96)[],uint256)",
  "function getActiveBids(uint256,uint256) view returns (uint256[],(address,uint96,uint32,uint8)[],uint256)",
]);

export const ladderAbi = parseAbi([
  "function pair() view returns (address)",
  "function ladderSold(uint256) view returns (uint256)",
  "function twapPrice() view returns (uint256)",
  "function rungPrice(uint256) view returns (uint256)",
  "function buyLadder(uint256 rung, uint256 amount) payable returns (uint256)",
]);
