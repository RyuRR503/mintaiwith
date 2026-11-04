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

describe("pre-check blocks", () => {
  it("mint command checks balance, Agent ID, slots and price with explicit signatures", () => {
    for (const t of [getBinanceCommands("zh")[1]!, getAgentCommands("zh")[1]!.text]) {
      expect(t).toContain("eth_getBalance");
      expect(t).toContain("function hasAgentId(address) view returns (bool)");
      expect(t).toContain("function mintsUsed(address) view returns (uint256)");
      expect(t).toContain("function mintPrice() view returns (uint256)");
    }
  });
  it("wallet check is first and read-only in both formats", () => {
    expect(getBinanceCommands("zh")[0]).toContain("只读查询，不发送任何交易");
    expect(getAgentCommands("zh")[0]!.text).toBe(getBinanceCommands("zh")[0]!);
  });
  it("read signatures exist in the vault ABI", async () => {
    const { READS } = await import("./checks");
    for (const [k, sig] of Object.entries(READS)) {
      if (k === "balance") continue;
      const name = sig.match(/function (\w+)\(/)![1];
      expect((vaultAbi as unknown as any[]).some(f => f.type === "function" && f.name === name)).toBe(true);
    }
  });
});
