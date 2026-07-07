# Robinhood Chain Quickstart

[![CI](https://github.com/ismailmoazami/robinhood-chain-quickstart/actions/workflows/test.yml/badge.svg)](https://github.com/ismailmoazami/robinhood-chain-quickstart/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Foundry](https://img.shields.io/badge/built%20with-Foundry-black)](https://book.getfoundry.sh/)

A Foundry template for getting a smart contract developer -- human or AI
agent -- from `git clone` to a deployed, verified contract on
[Robinhood Chain](https://docs.robinhood.com/chain) in under 10 minutes.

Robinhood Chain is a permissionless, EVM-compatible Layer 2 built on
Arbitrum Orbit, purpose-built for tokenized real-world assets and DeFi.
This repo ships four example contracts, deploy scripts, a full Uniswap
V2 + V3 interaction script (swap, add/remove liquidity, on both AMM
versions), tests including a live-fork integration suite, and CI/CD via
GitHub Actions.

If you're an AI coding agent, read **[AGENTS.md](./AGENTS.md)** instead --
it's a general reference for building anything on Robinhood Chain (wallets,
account abstraction, bridging, ecosystem addresses), not just this repo, in
a denser machine-oriented format.

## Quickstart

```bash
git clone https://github.com/ismailmoazami/robinhood-chain-quickstart.git
cd robinhood-chain-quickstart
git submodule update --init --recursive   # pulls forge-std + OpenZeppelin

forge build
forge test -vvv
```

That's enough to confirm your toolchain works. To actually deploy, you need
a funded wallet -- see [Wallet setup](#wallet-setup) below.

## What's inside

```
src/
  SimpleStorage.sol   # deploy this first -- confirms your toolchain works
  ERC20Token.sol       # OpenZeppelin ERC20 + burnable + owner-gated mint
  MyNFT.sol            # ERC721 with paid public minting + owner withdrawal
  RwaExample.sol        # ERC20 + compliance allowlist + owner-set reference price

script/
  DeploySimpleStorage.s.sol
  DeployToken.s.sol
  DeployNFT.s.sol
  DeployRwa.s.sol
  UniswapInteractions.s.sol   # V2 + V3: add/remove liquidity, swap

test/
  SimpleStorage.t.sol, ERC20Token.t.sol, MyNFT.t.sol, RwaExample.t.sol
  UniswapInteractions.t.sol   # forks Robinhood Chain mainnet live

.github/workflows/
  test.yml     # lint + build + test on every push/PR
  deploy.yml   # manual, dropdown-driven deploy + verify to testnet/mainnet
```

| Contract | What it demonstrates |
|---|---|
| `SimpleStorage` | The "does my toolchain work" contract -- deploy this first. |
| `ERC20Token` | Standard OpenZeppelin ERC20 + `ERC20Burnable`, owner-gated `mint`. |
| `MyNFT` | ERC721 with paid public minting (0.001 ETH), configurable base URI, owner withdrawal. |
| `RwaExample` (`SimpleRWA`) | The interesting one: an ERC20 with an owner-managed compliance allowlist gating every transfer, plus an owner-settable reference price -- the minimal shape of a real RWA/stock-token pattern, without the full KYC/custody/oracle machinery a production issuer would add. |

## Network reference

| | Mainnet | Testnet |
|---|---|---|
| RPC | `https://rpc.mainnet.chain.robinhood.com` | `https://rpc.testnet.chain.robinhood.com` |
| Chain ID | `4663` | `46630` |
| Explorer / verifier | `robinhoodchain.blockscout.com` | `explorer.testnet.chain.robinhood.com` |
| Faucet | -- | `faucet.testnet.chain.robinhood.com` |

This is a young chain (mainnet launched July 1, 2026). Run `cast chain-id
--rpc-url <url>` yourself if anything here feels stale.

## Wallet setup

Deployments in this repo use Foundry's encrypted keystore rather than a
plaintext private key in `.env` -- import your key once:

```bash
cast wallet import mywallet --interactive
```

Then every Makefile deploy/interact target takes `ACCOUNT=mywallet` (or
just omit it -- `mywallet` is the default) and `NETWORK=testnet` or
`NETWORK=mainnet`:

```bash
make deploy-storage NETWORK=testnet ACCOUNT=mywallet
```

Get testnet ETH from the faucet above before deploying there.

## Deploying and verifying

```bash
make deploy-storage NETWORK=testnet
make deploy-token NETWORK=testnet
make deploy SCRIPT=DeployNFT CONTRACT=DeployNFTScript NETWORK=testnet
make deploy-rwa NETWORK=testnet
```

Every deploy target passes `--legacy` -- Arbitrum Orbit chains (Robinhood
Chain included) need legacy-style transaction serialization for reliable
broadcast and verification.

Verify separately if a deploy's inline verification didn't go through:

```bash
make verify ADDRESS=0x... CONTRACT=ERC20Token NETWORK=testnet
```

Note: `RwaExample.sol` contains a contract named `SimpleRWA`, not
`RwaExample` -- verify it by path, not by matching filename to contract name:

```bash
forge verify-contract 0x... src/RwaExample.sol:SimpleRWA \
  --chain-id 46630 \
  --rpc-url https://rpc.testnet.chain.robinhood.com \
  --verifier blockscout \
  --verifier-url https://explorer.testnet.chain.robinhood.com/api/
```

Blockscout generally doesn't require a real API key for verification.

## Interacting with deployed contracts

```bash
make mint ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 NETWORK=testnet
make burn ADDRESS=0x... AMOUNT=1000000000000000000 NETWORK=testnet
make balance ADDRESS=0x... USER=0x... NETWORK=testnet

make mint-nft ADDRESS=0x... TO=0x... VALUE=0.001ether NETWORK=testnet
make set-base-uri ADDRESS=0x... URI=ipfs://... NETWORK=testnet

make set-eligibility ADDRESS=0x... USER=0x... ELIGIBLE=true NETWORK=testnet
make mint-rwa ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 NETWORK=testnet
make set-price ADDRESS=0x... PRICE=15000 NETWORK=testnet   # $150.00, in cents

make set-storage ADDRESS=0x... VALUE=42 NETWORK=testnet
make get-storage ADDRESS=0x... NETWORK=testnet
```

Run `make help` for the full list with usage strings.

## Uniswap V2 + V3 on Robinhood Chain

Uniswap v2, v3, v4, and UniswapX are all live on Robinhood Chain from
launch, with Uniswap serving as the chain's primary public AMM.
`script/UniswapInteractions.s.sol` drives both V2 and V3 through one
action-based script:

```bash
make uniswap-swap ACTION=v2_swap AMOUNT_A=10ether NETWORK=fork
make uniswap-add-lp ACTION=v3_add_lp AMOUNT_A=1000ether AMOUNT_B=10ether NETWORK=fork
```

Available actions: `v2_add_lp`, `v2_remove_lp`, `v2_swap`, `v3_add_lp`,
`v3_remove_lp`, `v3_swap`. `NETWORK=fork` runs against a local Anvil fork of
mainnet (start one with `make fork-start` in another terminal) -- the
sensible default while you're testing, since real swaps need real token
balances.

If you don't pass `TOKEN_A`/`TOKEN_B`, the script deploys mock `USDG`/`AAPL`
tokens for you automatically so you always have something to test with.

Contract addresses this repo targets on Robinhood Chain mainnet:

| Contract | Address |
|---|---|
| UniswapV2Factory | `0x8bcEaA40B9AcdfAedF85AdF4FF01F5Ad6517937f` |
| UniswapV2Router02 | `0x89e5DB8B5aA49aA85AC63f691524311AEB649eba` |
| UniswapV3Factory | `0x1f7d7550B1b028f7571E69A784071F0205FD2EfA` |
| SwapRouter02 (V3) | `0xCaf681a66D020601342297493863E78C959E5cb2` |
| NonfungiblePositionManager (V3) | `0x73991a25c818bf1f1128deaab1492d45638de0d3` |

These are recorded exactly as this repo currently uses them (also see
`AGENTS.md`, which additionally lists the V4 singleton/UniversalRouter/Permit2
addresses -- not yet wired into any script here). This chain launched days
ago; reconfirm on [Blockscout](https://robinhoodchain.blockscout.com) before
relying on any address for real funds.

## Testing

```bash
forge test -vvv                 # unit tests, no network needed
forge test --match-contract UniswapInteractionsTest -vvv   # forks mainnet live
```

The Uniswap test suite forks Robinhood Chain mainnet in `setUp()` and
degrades gracefully: if the RPC is unreachable, it logs a warning and every
fork-dependent test no-ops (passes trivially) instead of failing the whole
suite. That's deliberate -- CI shouldn't go red because of a third-party RPC
hiccup -- but it does mean a green checkmark on those specific tests doesn't
always mean they ran. If you're debugging Uniswap behavior, check the log
output for the "RPC is unreachable" warning before trusting a pass.

## CI/CD

**`test.yml`** runs on every push and PR to `main`/`master`: format check
(`forge fmt --check`), build with size report (`forge build --sizes`), and
the full test suite with gas reporting (`forge test --gas-report`).

**`deploy.yml`** is manual (`workflow_dispatch`) with dropdowns for which
contract to deploy and which network to target. To use it from GitHub's
Actions tab, set one required repository secret first:

- `DEPLOYER_PRIVATE_KEY` -- the workflow refuses to run without it.

Optionally set `MAINNET_RPC_URL` / `TESTNET_RPC_URL` secrets to use your own
RPC provider instead of the public endpoints (recommended for anything
beyond casual testnet use -- see the rate-limit note below).

## Production notes

- **Unaudited.** Every contract here is intentionally simple and meant for
  learning/onboarding, not production use as-is.
- **Public RPC endpoints are rate-limited.** Robinhood recommends Alchemy
  for production; QuickNode, Blockdaemon, dRPC, and Validation Cloud are
  also supported.
- **`RwaExample`'s compliance model is deliberately minimal** -- a single
  owner-controlled allowlist. A real RWA issuer needs KYC provider
  integration, custody, jurisdictional restrictions, and almost always a
  multisig or timelock behind the admin role rather than a single EOA.

## Contributing

Contract and script examples here are intentionally simple and unaudited --
this is an onboarding tool, not a production library. Addresses and chain
IDs may drift as this chain matures; if you spot something stale, please
open a PR.

## License

MIT -- see [LICENSE](./LICENSE).
