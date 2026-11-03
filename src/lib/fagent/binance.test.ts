import { describe, expect, it } from "./test-expect.ts";
import { binanceMint, binanceCard, getBinanceCommands, SIGNATURES } from "./binance.ts";
import { getAgentCommands } from "./commands";
import { vaultAbi } from "./vault-abi";

describe("binance wallet commands", () => {
  it("mint 7 sends 0.014 BNB", () => {
    const t = binanceMint(7);
    expect(t).toContain("function mint(uint256 count) payable");
    expect(t).toContain("14000000000000000 wei");
    expect(t.startsWith("你是我的币安 Agent 钱包助手")).toBe(true);
  });
  it("list converts price to wei with zero value", () => {
    const t = binanceCard("list", 500, "0.003");
    expect(t).toContain("[3000000000000000]");
    expect(t).toContain("- value：0");
  });
  it("covers every general command", () => {
    expect(getBinanceCommands("en")).toHaveLength(getAgentCommands("en").length);
  });
  it("signatures match the vault ABI", () => {
    for (const sig of Object.values(SIGNATURES)) {
      const [, name, args] = sig.match(/function (\w+)\((.*?)\)/)!;
      const fn = (vaultAbi as unknown as any[]).find(f => f.type === "function" && f.name === name);
      expect((args ?? "").split(",").filter(Boolean).map(a => a.trim().split(" ")[0])).toEqual(fn.inputs.map((i: any) => i.type));
      expect(sig.endsWith("payable")).toBe(fn.stateMutability === "payable");
    }
  });
});
