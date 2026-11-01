import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { isAddress } from "viem";
import { readSnapshot, readMarket, readWallet, readCard, readHistory } from "./chain.server";

export const getSnapshot = createServerFn({ method: "GET" }).handler(async () => {
  try { return { data: await readSnapshot(), error: null }; }
  catch { return { data: null, error: "链上数据暂时读取失败，请重试。" }; }
});
export const getMarket = createServerFn({ method: "GET" })
  .inputValidator((input: unknown) => z.object({ askCursor: z.string().regex(/^\d{1,7}$/), bidCursor: z.string().regex(/^\d{1,20}$/) }).parse(input))
  .handler(async ({ data }) => {
    try { return { data: await readMarket(data.askCursor, data.bidCursor), error: null }; }
    catch { return { data: null, error: "挂单读取失败，请重试；未用示例单替代。" }; }
  });
export const getWallet = createServerFn({ method: "GET" })
  .inputValidator((input: unknown) => z.object({ address: z.string().refine(isAddress, "地址格式不正确") }).parse(input))
  .handler(async ({ data }) => {
    try { return { data: await readWallet(data.address as `0x${string}`), error: null }; }
    catch { return { data: null, error: "钱包信息读取失败，请重试。" }; }
  });
export const getCard = createServerFn({ method: "GET" })
  .inputValidator((input: unknown) => z.object({ id: z.number().int().min(0).max(769999) }).parse(input))
  .handler(async ({ data }) => {
    try { return { data: await readCard(data.id), error: null }; }
    catch { return { data: null, error: "卡牌不存在、已销毁，或暂时无法读取。" }; }
  });
export const getHistory = createServerFn({ method: "GET" })
  .inputValidator((input: unknown) => z.object({ toBlock: z.string().regex(/^\d{1,20}$/).optional() }).parse(input))
  .handler(async ({ data }) => {
    try { return { data: await readHistory(data.toBlock), error: null }; }
    catch { return { data: null, error: "成交日志暂时无法读取，请重试。" }; }
  });