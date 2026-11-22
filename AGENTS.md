<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

## Architecture rules
- Standalone Solidity delivery packages keep source, tests, independently compiled flattened contracts and explicit verification limits together; never update the live ABI or deployment from a package-only request.
- FAGENT uses a root-scoped language provider and explicit Chinese/English dictionary with interpolated values; pass language into command generators so SSR and contract parameters never depend on mutable global locale state.
- FAGENT uses the Genesis pool-edition experience as its homepage at `/`, with no separate `/genesis` entry; market at `/market`, commands at `/commands`, vault at `/vault`, and rules at `/rules` remain independent leaves so existing chain integration is not changed by homepage replacement.
- FAGENT reads the NFT card and read-only lens through server functions and TanStack Query, discovering the vault/token from card getters only after launch; this prevents factory targets and retired vault data from entering live reads.
- Generate the contract ABI from the selected Solidity source; one shared deployment configuration supplies all readers and Agent commands to avoid address/signature drift.
- Transactions remain user-confirmed Binance Agent Wallet commands; the website never signs, submits transactions, or fabricates successful on-chain actions.
- Market math lives in the shared market utility: label fee-derived cumulative volume as an estimate and cap lowest-price purchase selections with the deployed MAX_BUY to avoid misleading totals or oversized transactions.
- Reuse FagentLogo and AgentCardArt with project-owned asset pointers; this preserves the approved identity after remixing.
- Keep colors and card treatments in semantic tokens in src/styles.css; this preserves the established theme across all card views.
- Genesis canvas art uses bounded per-particle paths and fully replaces every frame to prevent accumulated ghosts; deterministic prepainting, resize redraw, offscreen pause and static reduced-motion rendering preserve a visible composition.
- Keep drizzle/schema.ts blank; never replay copied CATCH migrations. Only explicitly requested schema or security changes may create new migrations.
- Retired CATCH places/spawns tables remain inaccessible to anon/authenticated roles; preserve records and service access so hardening does not change FAGENT chain reads.
- Preserve generated Cloud integration files but leave them unused by the standalone preview; platform-managed configuration must not be hand-edited.
- Agent commands come in two formats: general (full, verified-source) and Binance Wallet (short, explicit signature, no ABI lookup) in src/lib/fagent/binance.ts; Binance's built-in AI cannot resolve the proxy ABI.
- Inner pages (market, commands, vault, rules) render inside the shared SiteShell Genesis frame so every page matches the homepage and no legacy FAGENT layout remains.

- Render brand lettering through AntWordmark from FagentLogo across navigation, card headers, masthead and transitions; live text prevents stale raster lettering after renames.
- Keep new-edition source rules and calculations in antagent-edition; until its deployment is verified, show pending-state reference pages and never read or execute the retired deployment under new economics.

- Keep mint ladder pricing and Agent ID discounts together on /minting, reusing edition rules and the shared calculator so explanations and estimates stay consistent.
- Render edition token allocations from edition constants in an interactive donut with a dashed locked-team segment; never reuse retired allocation amounts in the new reference page.
- Keep requested preview fixtures in edition-demo and presentation components only, labeled as demo; never feed fixtures into chain readers, deployment state or executable wallet commands.
