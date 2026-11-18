import { queryOptions } from "@tanstack/react-query";
import { FAGENT } from "./config";
import { getSnapshot, getMarket } from "./chain.functions";
export const snapshotOptions = () => queryOptions({ queryKey: ["fagent", FAGENT.cards, "snapshot"], queryFn: () => getSnapshot(), staleTime: 15000, refetchInterval: 30000 });
export const marketOptions = () => queryOptions({ queryKey: ["fagent", FAGENT.cards, "market"], queryFn: () => getMarket({ data: { askCursor: "0", bidCursor: "0" } }), staleTime: 15000, refetchInterval: 30000 });