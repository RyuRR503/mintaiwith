import { test } from "node:test";
import assert from "node:assert/strict";
import { CARD_RULES, mintRemaining, mintSplit, batchForCard, canRedeem, previewSupply } from "./agent-card-model";

test("archive supply is 77 batches of 10000 with 9500 paid and 500 team cards", () => {
  assert.equal(CARD_RULES.supply, 770000);
  assert.equal(CARD_RULES.batches * CARD_RULES.cardsPerBatch, 770000);
  assert.equal(CARD_RULES.paidPerBatch, 9500);
  assert.equal(CARD_RULES.teamPerBatch, 500);
});
test("paid mint lifetime quota is 7, never negative", () => {
  assert.equal(mintRemaining(6), 1);
  assert.equal(mintRemaining(7), 0);
  assert.equal(mintRemaining(8), 0);
});
test("0.002 BNB mint splits 80 percent buyback and 20 percent ops", () => {
  assert.equal(CARD_RULES.mintPriceBnb, 0.002);
  assert.ok(Math.abs(mintSplit().buyback - 0.0016) < 1e-10);
  assert.ok(Math.abs(mintSplit().ops - 0.0004) < 1e-10);
});
test("redemption unlocks at 9500 paid cards, not 9499", () => {
  assert.equal(canRedeem(9499), false);
  assert.equal(canRedeem(9500), true);
});
test("human batch numbering changes at token 10000", () => {
  assert.equal(batchForCard(9999), 1);
  assert.equal(batchForCard(10000), 2);
});
test("market fill fee is 1 percent", () => {
  assert.equal(CARD_RULES.marketFeeBps, 100);
});
test("mock supply includes activated team cards and conserves 770000 total", () => {
  assert.equal(previewSupply().minted, 12631);
  assert.equal(previewSupply().remaining, 757369);
  assert.equal(previewSupply(1).minted, 12632);
  assert.equal(previewSupply(1).remaining, 757368);
  assert.equal(previewSupply(7).minted + previewSupply(7).remaining, 770000);
});