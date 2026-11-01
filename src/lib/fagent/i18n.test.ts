import { test } from "node:test";
import assert from "node:assert/strict";
import { mintCommand, bidCommand, batchBuyCommand } from "./commands";
import { normalizeLanguage } from "./i18n";
import { FAGENT } from "./config";

test("stored language accepts Chinese and English and safely defaults to Chinese", () => {
  assert.equal(normalizeLanguage("en"), "en");
  assert.equal(normalizeLanguage("zh"), "zh");
  assert.equal(normalizeLanguage(null), "zh");
  assert.equal(normalizeLanguage("fr"), "zh");
});
test("English mint preserves 2 cards, 0.004 BNB and the deployed vault", () => {
  const command = mintCommand(2, "en");
  assert.equal(command.match(/value=(\d+) wei/)?.[1], "4000000000000000");
  assert.ok(command.includes(FAGENT.vault));
  assert.ok(command.includes(FAGENT.token));
  assert.throws(() => mintCommand(8, "en"));
});
test("English batch-one bid escrows exactly 0.01 BNB for five cards", () => {
  const command = bidCommand("0.002", 5, 1, "en");
  assert.equal(command.match(/value=(\d+) wei/)?.[1], "10000000000000000");
  assert.ok(command.includes("parameters 2000000000000000, 5, 1"));
  assert.throws(() => bidCommand("0.002", 1, 78, "en"));
});
test("English bulk buy preserves exact per-card price caps and total", () => {
  const command = batchBuyCommand([{ id: 500, priceWei: "1000000000000000" }, { id: 501, priceWei: "2000000000000000" }], 150, "en");
  assert.equal(command.match(/value=(\d+) wei/)?.[1], "3000000000000000");
  assert.ok(command.includes("[500,501], [1000000000000000,2000000000000000]"));
});