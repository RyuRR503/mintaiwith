import { useCallback, useEffect, useMemo, useState } from "react";
import {
  createPublicClient,
  createWalletClient,
  custom,
  fallback,
  http,
  parseAbi,
  type Abi,
  type Address,
  type Hash,
} from "viem";
import { bsc } from "viem/chains";
import { toast } from "sonner";
import i18nData from "@/vaults/mintai/i18n.json";
import manifest from "@/vaults/mintai/manifest.json";

const LAUNCHER_ADDRESS = "0x2312DE6a1f6281c723F530b7E009F18c3c204BE9" as Address;
const VAULT_FACTORY_ADDRESS = "0x798D1a41C4EfEa013b1d293ae1134339b8CA31b6" as Address;

const RESOLVER_ABI = parseAbi([
  "function cards() view returns (address)",
  "function duel() view returns (address)",
  "function vaultOf(address) view returns (address)",
]);

const BSC_HEX_CHAIN_ID = "0x38";

type Eip1193Provider = {
  request: (args: { method: string; params?: unknown[] | Record<string, unknown> }) => Promise<unknown>;
  on?: (event: string, listener: (...args: unknown[]) => void) => void;
  removeListener?: (event: string, listener: (...args: unknown[]) => void) => void;
};

type ResolvedContract = {
  id: string;
  address: Address;
  chainId: number;
};

type ReadContractParams = {
  contract?: ResolvedContract | undefined;
  address?: Address | undefined;
  abi: Abi;
  functionName: string;
  args?: readonly unknown[] | undefined;
};

type SimulateContractParams = {
  contract?: ResolvedContract | undefined;
  address?: Address | undefined;
  abi: Abi;
  functionName: string;
  args?: readonly unknown[] | undefined;
  value?: bigint | undefined;
};

const publicClient = createPublicClient({
  chain: bsc,
  transport: fallback(
    [
      http("https://bsc-rpc.publicnode.com", { timeout: 12000, retryCount: 1 }),
      http("https://bsc-dataseed.bnbchain.org", { timeout: 10000, retryCount: 1 }),
      http("https://bsc-dataseed1.defibit.io", { timeout: 10000, retryCount: 0 }),
    ],
    { rank: false, retryCount: 1 },
  ),
});

const resolvedCache = new Map<string, Promise<ResolvedContract>>();

const translations = i18nData as Record<string, Record<string, string>>;

function getInjectedProvider(): Eip1193Provider | undefined {
  if (typeof window === "undefined") return undefined;
  const w = window as unknown as { ethereum?: Eip1193Provider; binancew3w?: { ethereum?: Eip1193Provider } };
  return w.ethereum ?? w.binancew3w?.ethereum;
}

function translate(key: string, fallbackText?: string, params?: Record<string, string | number>): string {
  const zhTable = translations["zh"];
  const enTable = translations["en"];
  let text = zhTable?.[key] ?? enTable?.[key] ?? fallbackText ?? key;
  if (params) {
    for (const [paramKey, paramValue] of Object.entries(params)) {
      text = text.replaceAll(`{${paramKey}}`, String(paramValue));
    }
  }
  return text;
}

async function resolveContractImpl(id: string, args: readonly unknown[] = []): Promise<ResolvedContract> {
  const cacheKey = `${id}:${args.map(String).join(",")}`;
  const cached = resolvedCache.get(cacheKey);
  if (cached) return cached;

  const task = (async (): Promise<ResolvedContract> => {
    if (id === "cards") {
      const address = await publicClient.readContract({
        address: LAUNCHER_ADDRESS,
        abi: RESOLVER_ABI,
        functionName: "cards",
      });
      return { id, address, chainId: 56 };
    }
    if (id === "duel") {
      const address = await publicClient.readContract({
        address: VAULT_FACTORY_ADDRESS,
        abi: RESOLVER_ABI,
        functionName: "duel",
      });
      return { id, address, chainId: 56 };
    }
    if (id === "vault") {
      const token = args[0] as Address | undefined;
      if (!token) throw new Error("Missing token address for vault resolution");
      const address = await publicClient.readContract({
        address: VAULT_FACTORY_ADDRESS,
        abi: RESOLVER_ABI,
        functionName: "vaultOf",
        args: [token],
      });
      return { id, address, chainId: 56 };
    }
    const direct = manifest.walletContracts.find((c) => c.id === id);
    if (direct) {
      return { id, address: direct.address as Address, chainId: direct.chainId };
    }
    throw new Error(`Unknown contract id: ${id}`);
  })().catch((err) => {
    resolvedCache.delete(cacheKey);
    throw err;
  });

  resolvedCache.set(cacheKey, task);
  return task;
}

async function readContractImpl<T>(params: ReadContractParams): Promise<T> {
  const address = params.contract?.address ?? params.address;
  if (!address) throw new Error("Missing contract address");
  const result = await publicClient.readContract({
    address,
    abi: params.abi,
    functionName: params.functionName,
    ...(params.args ? { args: params.args } : {}),
  });
  return result as T;
}

export function useFlapSdk(options: { chainId: number }) {
  const targetChainId = options.chainId;
  const [address, setAddress] = useState<Address | undefined>(undefined);
  const [chainId, setChainId] = useState<number | undefined>(undefined);

  useEffect(() => {
    const provider = getInjectedProvider();
    if (!provider) return;
    let active = true;

    const sync = async () => {
      try {
        const [accounts, rawChainId] = await Promise.all([
          provider.request({ method: "eth_accounts" }) as Promise<string[]>,
          provider.request({ method: "eth_chainId" }) as Promise<string>,
        ]);
        if (!active) return;
        const first = accounts[0];
        setAddress(first ? (first as Address) : undefined);
        if (rawChainId) setChainId(Number.parseInt(rawChainId, 16));
      } catch {
        // Ignore silent wallet discovery errors
      }
    };

    void sync();

    const onAccountsChanged = (accounts: unknown) => {
      const list = Array.isArray(accounts) ? accounts : [];
      const first = typeof list[0] === "string" ? (list[0] as Address) : undefined;
      setAddress(first);
    };
    const onChainChanged = (nextChain: unknown) => {
      if (typeof nextChain === "string") {
        setChainId(Number.parseInt(nextChain, 16));
      }
    };

    provider.on?.("accountsChanged", onAccountsChanged);
    provider.on?.("chainChanged", onChainChanged);
    return () => {
      active = false;
      provider.removeListener?.("accountsChanged", onAccountsChanged);
      provider.removeListener?.("chainChanged", onChainChanged);
    };
  }, []);

  const connect = useCallback(async () => {
    const provider = getInjectedProvider();
    if (!provider) {
      toast.error("未检测到浏览器钱包，请使用 Binance Wallet 或 MetaMask 打开。");
      return;
    }
    try {
      const accounts = (await provider.request({ method: "eth_requestAccounts" })) as string[];
      const rawChainId = (await provider.request({ method: "eth_chainId" })) as string;
      const first = accounts[0];
      setAddress(first ? (first as Address) : undefined);
      if (rawChainId) setChainId(Number.parseInt(rawChainId, 16));
    } catch {
      toast.error("钱包连接已取消。");
    }
  }, []);

  const switchChain = useCallback(async () => {
    const provider = getInjectedProvider();
    if (!provider) {
      toast.error("未检测到浏览器钱包。");
      return;
    }
    try {
      await provider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: BSC_HEX_CHAIN_ID }],
      });
      setChainId(targetChainId);
    } catch (error: unknown) {
      const code = (error as { code?: number })?.code;
      if (code === 4902) {
        await provider.request({
          method: "wallet_addEthereumChain",
          params: [
            {
              chainId: BSC_HEX_CHAIN_ID,
              chainName: "BNB Smart Chain",
              nativeCurrency: { name: "BNB", symbol: "BNB", decimals: 18 },
              rpcUrls: ["https://bsc-dataseed.bnbchain.org/"],
              blockExplorerUrls: ["https://bscscan.com/"],
            },
          ],
        });
        setChainId(targetChainId);
      } else {
        throw error;
      }
    }
  }, [targetChainId]);

  const simulateContract = useCallback(
    async (params: SimulateContractParams) => {
      const targetAddress = params.contract?.address ?? params.address;
      if (!targetAddress) throw new Error("Missing contract address");
      if (!address) throw new Error("Wallet not connected");
      const result = await publicClient.simulateContract({
        account: address,
        address: targetAddress,
        abi: params.abi,
        functionName: params.functionName,
        ...(params.args ? { args: params.args } : {}),
        ...(params.value !== undefined ? { value: params.value } : {}),
      });
      return result;
    },
    [address],
  );

  const writeContract = useCallback(
    async (request: unknown): Promise<Hash> => {
      const provider = getInjectedProvider();
      if (!provider || !address) throw new Error("Wallet not connected");
      const walletClient = createWalletClient({
        account: address,
        chain: bsc,
        transport: custom(provider),
      });
      return walletClient.writeContract(request as Parameters<typeof walletClient.writeContract>[0]);
    },
    [address],
  );

  const waitForTx = useCallback(async (hash: Hash) => {
    return publicClient.waitForTransactionReceipt({ hash });
  }, []);

  const isConnected = Boolean(address);
  const isWrongNetwork = isConnected && chainId !== undefined && chainId !== targetChainId;

  return useMemo(
    () => ({
      resolveContract: resolveContractImpl,
      readContract: readContractImpl,
      simulateContract,
      writeContract,
      waitForTx,
      i18n: { t: translate },
      notify: {
        success: (message: string) => toast.success(message),
        error: (message: string) => toast.error(message),
      },
      wallet: {
        address,
        isConnected,
        isWrongNetwork,
        connect,
        switchChain,
      },
    }),
    [address, isConnected, isWrongNetwork, connect, switchChain, simulateContract, writeContract, waitForTx],
  );
}