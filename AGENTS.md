# AGENTS.md -- Building on Robinhood Chain

A general-purpose reference for AI agents (Claude Code, Cursor, Antigravity, etc.) and
their humans building *anything* on Robinhood Chain -- not just this repo.
Flat facts, imperative instructions, minimal prose. Repo-specific
conventions for this particular Foundry template are in the last section;
everything above that applies regardless of what project you're in.

Sources: docs.robinhood.com/chain, docs.morpho.org, alchemy.com. Verified
July 2026. This chain is new (mainnet launched July 1, 2026) -- re-check
docs.robinhood.com/chain before trusting anything here past a few months old.

## 1. What Robinhood Chain is

Permissionless, EVM-compatible Layer 2, built on Arbitrum Orbit, settling
to Ethereum with blobs for data availability. Purpose-built for tokenized
real-world assets (Stock Tokens, ETFs) plus general DeFi. Native gas token
is ETH. Fully permissionless deployment -- no allowlist, no approval needed.

## 2. Network facts (confirmed against official docs)

| Property | Mainnet | Testnet |
|---|---|---|
| Chain ID | `4663` | `46630` |
| Public RPC | `https://rpc.mainnet.chain.robinhood.com` | `https://rpc.testnet.chain.robinhood.com` |
| Alchemy RPC | `https://robinhood-mainnet.g.alchemy.com/v2/{API_KEY}` | `https://robinhood-testnet.g.alchemy.com/v2/{API_KEY}` |
| Block explorer | `robinhoodchain.blockscout.com` | `explorer.testnet.chain.robinhood.com` |
| Sequencer feed (WS) | `wss://feed.mainnet.chain.robinhood.com` | `wss://feed.testnet.chain.robinhood.com` |
| Faucet | -- | `faucet.testnet.chain.robinhood.com` |
| Gas token | ETH | ETH |

Public RPC endpoints are rate-limited; use a provider (Alchemy recommended,
also QuickNode/Blockdaemon/dRPC/Validation Cloud) for anything production.

Always double check with `cast chain-id --rpc-url <url>` before broadcasting
anything you care about -- this is a young chain and details can shift.

## 3. Creating a wallet

**Simple EOA (fastest path, good for testing/scripting):**
```bash
cast wallet new                      # generates a fresh private key + address
# fund it: bridge from Ethereum, or use the testnet faucet above
```
Add the network to MetaMask/Rabby manually using the Chain ID + RPC + explorer
values in the table above, or via `wallet_addEthereumChain` programmatically.

**Smart account / account abstraction (for production apps, gas sponsorship,
batching, session keys):** Robinhood Chain has first-class ERC-4337 support
and also supports EIP-7702 (lets an existing EOA delegate to smart-account
code without changing its address). Three supported providers:

| Provider | Use for |
|---|---|
| Alchemy (`@alchemy/wallet-apis`) | Programmable wallets, gas sponsorship via Gas Manager policies, batching |
| ZeroDev (`@zerodev/sdk`) | Embeddable smart AA wallets, cross-chain execution |
| Privy | Embedded wallets + AA tooling, good for consumer-facing apps |

Deployed ERC-4337 infra on Robinhood Chain (same addresses for both providers
since they use the standard EntryPoint):

| Contract | Address |
|---|---|
| EntryPoint v0.6.0 | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` |
| EntryPoint v0.7.0 | `0x0000000071727De22E5E9d8BAf0edAc6f37da032` |
| EntryPoint v0.8.0 | `0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108` |
| Safe 4337 Module v0.3.0 (for EP v0.7.0) | `0x75cf11467937ce3F2f357CE24ffc3DBF8fD5c226` |

Minimal Alchemy smart-account send (sponsored gas):
```ts
import { createSmartWalletClient, alchemyWalletTransport } from "@alchemy/wallet-apis";
import { robinhoodMainnet } from "@alchemy/common/chains";
import { privateKeyToAccount } from "viem/accounts";

const client = createSmartWalletClient({
  transport: alchemyWalletTransport({ apiKey: "YOUR_API_KEY" }),
  chain: robinhoodMainnet,
  signer: privateKeyToAccount("0xYOUR_PRIVATE_KEY"),
  paymaster: { policyId: "YOUR_GAS_MANAGER_POLICY_ID" },
});
const { id } = await client.sendCalls({ calls: [{ to: "0x...", value: 0n }] });
```

## 4. Getting funds onto the chain

| Route | Type | Speed | Use when |
|---|---|---|---|
| Testnet faucet | -- | instant | testing, no real funds needed |
| Arbitrum canonical bridge (`portal.arbitrum.io/bridge`) | Trustless L1↔L2 | ~10 min deposit / ~7 day withdrawal | moving ETH/ERC-20s, no trust assumptions |
| LayerZero OFT / Stargate | Messaging + omnichain transfer | minutes | moving WBTC, USDG, other OFTs |
| Chainlink CCIP | Messaging + token transfer | minutes | bridge-and-act atomically (e.g. bridge then deposit into a lending market) |
| Relay / Across | Intents-based bridge | seconds | fast, cheap transfers |
| LiFi / 0x | Swap aggregators | seconds-minutes | swap-and-bridge in one step |

Withdrawals back to Ethereum always take the full ~7-day Arbitrum challenge
period, regardless of which bridge you used to deposit -- this is a fraud-proof
security property, not a UX bug. Warn users of this if you're building
anything with a withdraw flow.

A bridged ERC-20's address on Robinhood Chain is NOT the same as its Ethereum
address. Resolve it via `calculateL2TokenAddress` on the L2 Gateway Router,
or look it up on the Protocol Contracts page.

## 5. Solidity development conventions

- **Full EVM Compatibility**: Foundry, Hardhat, ethers.js, viem, and Wagmi all work unmodified. No custom precompiles are required for basic contracts.
- **Target EVM Version**: `cancun` (contracts are optimized specifically for the Cancun EVM version on Robinhood Chain).
- **Gas Model**: Gas has two components: L2 execution fee + L1 data fee (proportional to calldata size, posted to Ethereum). Calldata size should be minimized (e.g., pack args, use ERC-4337 batching).
- **Fee Token**: ETH is the native gas token.
- **Transaction Formatting**: Transactions on Arbitrum Orbit chains like Robinhood Chain often require the `--legacy` flag when broadcasting via Foundry/Cast to avoid EIP-1559 type-2 serialization mismatches.

## 6. Ecosystem contracts (confirmed deployed on Robinhood Chain mainnet)

### Core Tokens & RWAs
| Token | Address | Description |
|---|---|---|
| **WETH** | `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` | Wrapped Ether |
| **USDG** | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` | Canonical USD Stablecoin |
| **AAPL** | `0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9` | Apple Inc. Stock Token |
| **NVDA** | `0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC` | NVIDIA Corp. Stock Token |
| **TSLA** | `0x322F0929c4625eD5bAd873c95208D54E1c003b2d` | Tesla, Inc. Stock Token |
| **QQQ** | `0xD5f3879160bc7c32ebb4dC785F8a4F505888de68` | Invesco QQQ ETF Token |

### Uniswap Protocol Deployments

#### Uniswap V4
| Contract | Address | Description |
|---|---|---|
| **PoolManager** | `0x8366a39cc670b4001a1121b8f6a443a643e40951` | Centralized state manager for all V4 pools |
| **PositionDescriptor** | `0x9639443158e8c5efa35bd45287bf2effd3d8dc06` | Decodes position details and renders metadata |
| **PositionManager** | `0x58daec3116aae6d93017baaea7749052e8a04fa7` | Standard ERC721 position manager for V4 |
| **Quoter** | `0x8dc178efb8111bb0973dd9d722ebeff267c98f94` | Provides off-chain quotes for V4 swaps |
| **StateView** | `0xf3334192d15450cdd385c8b70e03f9a6bd9e673b` | State viewing lens contract |
| **UniversalRouter** | `0x8876789976decbfcbbbe364623c63652db8c0904` | Entry point for swaps across V4, V3, and V2 |
| **Permit2** | `0x000000000022D473030F116dDEE9F6B43aC78BA3` | Token approvals and transfers protocol |

#### Uniswap V3
| Contract | Address | Description |
|---|---|---|
| **UniswapV3Factory** | `0x1f7d7550b1b028f7571e69a784071f0205fd2efa` | Deploys V3 pools and manages protocol fees |
| **SwapRouter02** | `0xcaf681a66d020601342297493863e78c959e5cb2` | Main execution router for V3 and V2 swaps |
| **NonfungiblePositionManager** | `0x73991a25c818bf1f1128deaab1492d45638de0d3` | Tracks and manages V3 liquidity positions |
| **QuoterV2** | `0x33e885ed0ec9bf04ecfb19341582aadcb4c8a9e7` | Calculates swap results off-chain for V3 |

#### Uniswap V2
| Contract | Address | Description |
|---|---|---|
| **UniswapV2Factory** | `0x8bceaa40b9acdfaedf85adf4ff01f5ad6517937f` | Creates and manages standard ERC20/ERC20 pairs |
| **UniswapV2Router02** | `0x89e5db8b5aa49aa85ac63f691524311aeb649eba` | Router for basic swaps and liquidity management |

### Other Protocols
| Protocol | Address / note |
|---|---|
| **Morpho Blue** | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` -- same deterministic address on every chain Morpho is deployed to |
| **Chainlink** | Official oracle + cross-chain data partner; feeds Stock Token prices (NVDA, AAPL, etc.) |
| **BitGo** | Institutional custody partner (not directly relevant to onchain dev, but shows up in docs) |

## 7. Testing & deployment patterns

- Unit test with mocks as normal (`forge test`).
- Fork test against live state for integrations:
  `forge test --fork-url https://rpc.mainnet.chain.robinhood.com`
- Deploy with `forge script` using Forge's secure keystores or raw key broadcast.
- Verify contracts using Blockscout verifier API:
  - Testnet: `--verify --verifier blockscout --verifier-url https://explorer.testnet.chain.robinhood.com/api/`
  - Mainnet: `--verify --verifier blockscout --verifier-url https://robinhoodchain.blockscout.com/api/`
  - Note: Blockscout verification generally does not require a real API key; `empty` works as the key value.
- `robinhoodMainnet` / testnet chain definitions exist in `viem/chains` and `@alchemy/common/chains` if writing TypeScript tooling.

## 8. Rules for agents

1. Never hardcode a chain ID from memory without cross-checking section 2.
2. Never assume Uniswap's Robinhood Chain deployment matches standard V2/V3 ABIs. Confirm on Blockscout first.
3. Never invent a bridged token's L2 address -- resolve it via the Gateway Router or Protocol Contracts page, don't guess from the L1 address.
4. If a task involves moving real user funds through the main Robinhood bridge, mention the 7-day withdrawal challenge period explicitly.
5. Prefer ERC-4337/EIP-7702 patterns (batching, sponsorship) over raw EOA transactions when building anything user-facing.

---

## Repo-specific: this Foundry template

Everything below applies only to *this* repository, not Robinhood Chain in general.

### What this repo is
A Foundry quickstart template containing example contracts (SimpleStorage, ERC20Token, MyNFT, and SimpleRWA), corresponding deployment scripts, and unit tests, meant to get a new contract deployed, verified, and interacted with on Robinhood Chain testnet or mainnet using Forge/Cast.

### Repo layout
```
src/
  SimpleStorage.sol       # A basic contract to store and retrieve a single uint256.
  ERC20Token.sol          # Standard ERC20 token with minting (restricted to owner) and burning (OZ v5).
  MyNFT.sol               # ERC721 NFT contract with a common base URI, public minting (0.001 ETH), and owner withdrawal.
  RwaExample.sol          # SimpleRWA contract: a compliance-gated ERC20 RWA token with eligibility allowlist and price/NAV.
script/
  DeploySimpleStorage.s.sol  # Deployment script for SimpleStorage (contract DeployScript).
  DeployToken.s.sol          # Deployment script for ERC20Token (contract DeployScript).
  DeployNFT.s.sol            # Deployment script for MyNFT (contract DeployNFTScript).
  DeployRwa.s.sol            # Deployment script for SimpleRWA (contract DeployScript).
test/
  SimpleStorage.t.sol     # Unit tests for SimpleStorage.
  ERC20Token.t.sol        # Unit tests for ERC20Token.
  MyNFT.t.sol             # Unit tests for MyNFT.
  RwaExample.t.sol        # Compliance, transferability, and minting tests for SimpleRWA.
```

### Commands

**Compilation & Testing:**
```bash
make build          # Or: forge build
forge test          # Run all unit tests
```

**Deployment via Makefile:**
Deployments use Forge keystores. Before deploying, import your private key to your local keystore using:
```bash
cast wallet import mywallet --interactive
```
Then run the deployment command (setting `NETWORK` to `testnet` or `mainnet`, and `ACCOUNT` to your imported keystore name):

- **Deploy SimpleStorage:**
  ```bash
  make deploy-storage NETWORK=testnet ACCOUNT=mywallet
  ```
- **Deploy SimpleRWA:**
  ```bash
  make deploy-rwa NETWORK=testnet ACCOUNT=mywallet
  ```
- **Deploy ERC20Token:**
  ```bash
  make deploy SCRIPT=DeployToken CONTRACT=DeployScript NETWORK=testnet ACCOUNT=mywallet
  ```
- **Deploy MyNFT (Note `CONTRACT=DeployNFTScript`):**
  ```bash
  make deploy SCRIPT=DeployNFT CONTRACT=DeployNFTScript NETWORK=testnet ACCOUNT=mywallet
  ```

**Contract Verification:**
```bash
# Verify ERC20Token
make verify ADDRESS=0x... CONTRACT=ERC20Token NETWORK=testnet

# Verify SimpleRWA (Note: contract name is SimpleRWA but source filename is RwaExample)
forge verify-contract 0x... src/RwaExample.sol:SimpleRWA \
  --chain-id 46630 \
  --rpc-url https://rpc.testnet.chain.robinhood.com \
  --verifier blockscout \
  --verifier-url https://explorer.testnet.chain.robinhood.com/api/
```

**Ecosystem & Contract Interactions:**

- **Simple Storage:**
  ```bash
  make set-storage ADDRESS=0x... VALUE=42 NETWORK=testnet ACCOUNT=mywallet
  make get-storage ADDRESS=0x... NETWORK=testnet
  ```
- **ERC20 Token:**
  ```bash
  make mint ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 NETWORK=testnet ACCOUNT=mywallet
  make burn ADDRESS=0x... AMOUNT=1000000000000000000 NETWORK=testnet ACCOUNT=mywallet
  make balance ADDRESS=0x... USER=0x... NETWORK=testnet
  ```
- **MyNFT Collection:**
  ```bash
  make mint-nft ADDRESS=0x... TO=0x... VALUE=0.001ether NETWORK=testnet ACCOUNT=mywallet
  make set-base-uri ADDRESS=0x... URI=ipfs://... NETWORK=testnet ACCOUNT=mywallet
  ```
- **SimpleRWA (Compliance Gated):**
  ```bash
  # Grant eligibility to a user
  make set-eligibility ADDRESS=0x... USER=0x... ELIGIBLE=true NETWORK=testnet ACCOUNT=mywallet
  # Mint RWA tokens to an eligible recipient
  make mint-rwa ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 NETWORK=testnet ACCOUNT=mywallet
  # Set reference price per share in cents (e.g., $150.00 = 15000)
  make set-price ADDRESS=0x... PRICE=15000 NETWORK=testnet ACCOUNT=mywallet
  ```

### Rules for agents editing this repo specifically
1. **Keystore Deployments**: Never hardcode private keys. Use the Makefile targets with `ACCOUNT=<name>` (utilizing Foundry's keystores) or the `--account` parameter in raw script calls.
2. **Contract Naming**: Keep in mind that `src/RwaExample.sol` contains the `SimpleRWA` contract and its deployment script in `script/DeployRwa.s.sol` yields a `SimpleRWA` instance. Similarly, the deployment script in `script/DeployNFT.s.sol` defines `DeployNFTScript` rather than the default `DeployScript`.
3. **Arbitrum Orbit Legacy Tx requirement**: Always pass `--legacy` when executing deployment or write transactions via Forge/Cast on Robinhood Chain to avoid serialization issues.
4. **Follow Formatting**: Run `forge fmt` before submitting any code changes.
5. **Simplicity over Complexity**: This is an onboarding/quickstart repository. Keep example contracts and tests simple. Do not add complex governance or multi-sig abstractions unless explicitly asked.
