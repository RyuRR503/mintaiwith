import { test } from "node:test";
import assert from "node:assert/strict";
import { encodeFunctionData, decodeFunctionData } from "viem";
import { cardsAbi } from "./cards-abi";
import { FAGENT, liveSupply, redemptionReady, launchPhase, deployedAddress, ZERO_ADDRESS } from "./config";
import { mintCommand, bidCommand, batchBuyCommand } from "./commands";
import { estimatedMarketVolume, formatBnb, purchaseSelection, saleCardIds } from "./market";

test("deployment uses NFT card, lens and factories as distinct targets", () => {
  assert.equal(FAGENT.cards, "0xc781e11A506F9d8DfCd38B1125A4ccDC199EB36F");
  assert.equal(FAGENT.launcherFactory, "0x2312DE6a1f6281c723F530b7E009F18c3c204BE9");
  assert.equal(FAGENT.factory, "0x798D1a41C4EfEa013b1d293ae1134339b8CA31b6");
  assert.equal(FAGENT.orderbook, "0x85b6CfD82a9B0589dc255cB47a1351181366Dba5");
  assert.equal(FAGENT.duel, "0x2617efF6dEB81cD398c2C7d774BE1Fc9714e4dec");
  assert.equal(FAGENT.upgradeManager, "0xF3213fbDF1D1C993362725a68AcBa883520D7D2C5");
  assert.equal(new Set(Object.values(FAGENT).filter(x => typeof x === "string")).size, 6);
});
test("pool cannot open just because 20000 cards sold, vault waits for launch", () => {
  assert.equal(launchPhase(false, 20000, 100, 100, 101), "ready");
  assert.equal(launchPhase(true, 20000, 100, 100, 101), "open");
  assert.equal(deployedAddress(ZERO_ADDRESS), false);
  assert.equal(deployedAddress(FAGENT.upgradeManager), false);
});
test("refund begins strictly after the 7-day presale or stalled launch deadline", () => {
  assert.equal(launchPhase(false, 19999, 604800, 0, 604800), "presale");
  assert.equal(launchPhase(false, 19999, 604800, 0, 604801), "refund");
  assert.equal(launchPhase(false, 20000, 1, 100, 604900), "ready");
  assert.equal(launchPhase(false, 20000, 1, 100, 604901), "refund");
});
test("live supply counts materialized NFTs separately from activated team rights", () => {
  assert.deepEqual(liveSupply(19, 0, 770000), { minted: 19, remaining: 769981, batch: 1, batchPaid: 19, activatedTeam: 1 });
  assert.equal(liveSupply(9500, 500, 770000).batch, 2);
  assert.equal(liveSupply(731500, 38500, 770000).remaining, 0);
});
test("open-batch redemption unlocks at exactly 7 days, not one second earlier", () => {
  assert.equal(redemptionReady(false, 100, 604800, 604899), false);
  assert.equal(redemptionReady(false, 100, 604800, 604900), true);
  assert.equal(redemptionReady(true, 100, 604800, 101), true);
});
test("issuance progress uses cumulative minted cards out of 770000, not active dividend shares", () => {
  const supply = liveSupply(34300, 1762, 770000);
  assert.equal(supply.minted, 36062);
  assert.equal(supply.remaining, 733938);
  assert.equal((supply.minted / 770000 * 100).toFixed(2), "4.68");
});
test("selected ABI supports count-based mint, not obsolete mint()", () => {
  const data = encodeFunctionData({ abi: cardsAbi, functionName: "mint", args: [2n, 0n] });
  assert.deepEqual(decodeFunctionData({ abi: cardsAbi, data }).args, [2n, 0n]);
  assert.ok(mintCommand(2).includes("value=4900000000000000 wei"));
  assert.throws(() => mintCommand(11));
});
test("human batch 1 maps to batchPlusOne 1 and 5 cards escrow exactly 0.01 BNB", () => {
  const command = bidCommand("0.002", 5, 0);
  assert.ok(command.includes("参数 2000000000000000, 5"));
  assert.ok(command.includes("value=10000000000000000 wei"));
});
test("order commands reject invalid amount, quantity and batch", () => {
  assert.throws(() => bidCommand("0", 1, 0));
  assert.throws(() => bidCommand("0.002", 4294967296, 0));
  assert.throws(() => bidCommand("0.002", 1, 78));
  assert.throws(() => bidCommand("0.0000000000000000001", 1, 0));
});
test("cumulative volume is estimated from the selected contract's 1 percent fee", () => {
  assert.equal(estimatedMarketVolume("50000000000000", 100), "0.005");
  assert.equal(estimatedMarketVolume("0", 100), "0");
});
test("BNB amounts display with at most 4 decimals and no trailing zeros", () => {
  assert.equal(formatBnb(21873828437259251300n), "21.8738");
  assert.equal(formatBnb(2000000000000000n), "0.002");
  assert.equal(formatBnb(0n), "0");
  assert.equal(formatBnb(100n), "0");
  assert.equal(formatBnb(50000000000000n), "0");
});
test("quick purchase selects cheapest cards and respects the 150 card contract cap", () => {
  const asks = Array.from({ length: 151 }, (_, id) => ({ id, priceWei: String(BigInt(151 - id) * 1000000000000000n) }));
  const selection = purchaseSelection(asks, 150);
  assert.equal(selection.cards.length, 150);
  assert.equal(selection.cards[0]?.id, 150);
  assert.equal(selection.cards.at(-1)?.id, 1);
  assert.equal(selection.totalWei, "11325000000000000000");
  assert.throws(() => batchBuyCommand(asks, 150));
});
test("batch purchase pays the sum of individual price caps", () => {
  const command = batchBuyCommand([{ id: 500, priceWei: "1000000000000000" }, { id: 501, priceWei: "2000000000000000" }], 150);
  assert.ok(command.includes("参数 [500,501], [1000000000000000,2000000000000000]"));
  assert.ok(command.includes("value=3000000000000000 wei"));
});
test("sell-to-bid accepts at most 250 unique valid card IDs", () => {
  assert.equal(saleCardIds(Array.from({ length: 250 }, (_, i) => String(i + 1)).join(","), 250).length, 250);
  assert.deepEqual(saleCardIds(Array.from({ length: 251 }, (_, i) => String(i + 1)).join(","), 250), []);
  assert.deepEqual(saleCardIds("500,500,501", 250), [500, 501]);
  assert.deepEqual(saleCardIds("777778", 250), []);
});