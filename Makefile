.PHONY: build clean help deploy verify mint burn balance mint-nft set-base-uri

# Include .env file
-include .env
export

# --- General Configuration ---
NETWORK ?= testnet
ACCOUNT ?= mywallet
VALUE   ?= 0.001ether

# Default script parameters (used for generic deploy target)
SCRIPT   ?= DeployToken
CONTRACT ?= DeployScript

# --- Network RPC & Explorer Settings ---

# Robinhood Chain Testnet
TESTNET_RPC          ?= https://rpc.testnet.chain.robinhood.com
TESTNET_CHAIN        ?= 46630
TESTNET_VERIFIER_URL ?= https://explorer.testnet.chain.robinhood.com/api/

# Robinhood Chain Mainnet
MAINNET_RPC          ?= https://rpc.mainnet.chain.robinhood.com
MAINNET_CHAIN        ?= 4663
MAINNET_VERIFIER_URL ?= https://robinhoodchain.blockscout.com/api/

# Dynamically set network variables based on NETWORK parameter
ifeq ($(NETWORK),mainnet)
	ACTIVE_RPC          := $(MAINNET_RPC)
	ACTIVE_CHAIN        := $(MAINNET_CHAIN)
	ACTIVE_VERIFIER_URL := $(MAINNET_VERIFIER_URL)
	SENDER_FLAG         := --account $(ACCOUNT)
else ifeq ($(NETWORK),fork)
	ACTIVE_RPC          := http://127.0.0.1:8545
	ACTIVE_CHAIN        := 4663
	ACTIVE_VERIFIER_URL := $(MAINNET_VERIFIER_URL)
	SENDER_FLAG         := --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
else
	ACTIVE_RPC          := $(TESTNET_RPC)
	ACTIVE_CHAIN        := $(TESTNET_CHAIN)
	ACTIVE_VERIFIER_URL := $(TESTNET_VERIFIER_URL)
	SENDER_FLAG         := --account $(ACCOUNT)
endif


# --- Commands ---

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Compile all smart contracts
	forge build

clean: ## Remove compilation artifacts
	forge clean

# --- Generic Deployment & Verification ---

deploy: ## Deploy using a script (usage: make deploy [SCRIPT=DeployToken] [CONTRACT=DeployScript] [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Deploying using script/$(SCRIPT).s.sol:$(CONTRACT) on $(NETWORK) using account $(ACCOUNT)..."
	forge script script/$(SCRIPT).s.sol:$(CONTRACT) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--broadcast \
		--legacy

verify: ## Verify a contract (usage: make verify ADDRESS=0x... CONTRACT=ERC20Token [NETWORK=testnet])
	@echo "Verifying $(CONTRACT) at $(ADDRESS) on $(NETWORK)..."
	forge verify-contract $(ADDRESS) \
		src/$(CONTRACT).sol:$(CONTRACT) \
		--chain-id $(ACTIVE_CHAIN) \
		--rpc-url $(ACTIVE_RPC) \
		--verifier blockscout \
		--verifier-url $(ACTIVE_VERIFIER_URL)

# --- ERC20 Interactions ---

deploy-token: ## Deploy ERC20Token (usage: make deploy-token [NETWORK=testnet] [ACCOUNT=mywallet])
	@$(MAKE) deploy SCRIPT=DeployToken CONTRACT=DeployScript NETWORK=$(NETWORK) ACCOUNT=$(ACCOUNT)

mint: ## Mint ERC20 tokens (usage: make mint ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Minting $(AMOUNT) tokens to $(TO) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "mint(address,uint256)" $(TO) $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

burn: ## Burn ERC20 tokens (usage: make burn ADDRESS=0x... AMOUNT=1000000000000000000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Burning $(AMOUNT) tokens on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "burn(uint256)" $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

balance: ## Check ERC20 token balance (usage: make balance ADDRESS=0x... USER=0x... [NETWORK=testnet])
	@cast call $(ADDRESS) "balanceOf(address)(uint256)" $(USER) \
		--rpc-url $(ACTIVE_RPC)

# --- NFT Interactions ---

deploy-nft: ## Deploy MyNFT (usage: make deploy-nft [NETWORK=testnet] [ACCOUNT=mywallet])
	@$(MAKE) deploy SCRIPT=DeployNFT CONTRACT=DeployNFTScript NETWORK=$(NETWORK) ACCOUNT=$(ACCOUNT)

mint-nft: ## Mint an NFT (usage: make mint-nft ADDRESS=0x... TO=0x... [VALUE=0.001ether] [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Minting NFT to $(TO) on $(NETWORK) using account $(ACCOUNT) with payment $(VALUE)..."
	cast send $(ADDRESS) "mintNFT(address)" $(TO) \
		--value $(VALUE) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

set-base-uri: ## Set NFT base URI (usage: make set-base-uri ADDRESS=0x... URI=ipfs://... [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting base URI of $(ADDRESS) to $(URI) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "setBaseURI(string)" $(URI) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

# --- Simple RWA Interactions ---

deploy-rwa: ## Deploy SimpleRWA (usage: make deploy-rwa [NETWORK=testnet] [ACCOUNT=mywallet])
	@$(MAKE) deploy SCRIPT=DeployRwa CONTRACT=DeployScript NETWORK=$(NETWORK) ACCOUNT=$(ACCOUNT)

mint-rwa: ## Mint SimpleRWA tokens (usage: make mint-rwa ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Minting $(AMOUNT) tokens to $(TO) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "mint(address,uint256)" $(TO) $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

set-eligibility: ## Set eligibility of an address (usage: make set-eligibility ADDRESS=0x... USER=0x... ELIGIBLE=true [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting eligibility of $(USER) to $(ELIGIBLE) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "setEligibility(address,bool)" $(USER) $(ELIGIBLE) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

set-price: ## Set reference price per share in cents (usage: make set-price ADDRESS=0x... PRICE=15000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting price per share of $(ADDRESS) to $(PRICE) cents on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "setPricePerShareCents(uint256)" $(PRICE) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

# --- Simple Storage Interactions ---

deploy-storage: ## Deploy SimpleStorage (usage: make deploy-storage [NETWORK=testnet] [ACCOUNT=mywallet])
	@$(MAKE) deploy SCRIPT=DeploySimpleStorage CONTRACT=DeployScript NETWORK=$(NETWORK) ACCOUNT=$(ACCOUNT)

set-storage: ## Set a value in SimpleStorage (usage: make set-storage ADDRESS=0x... VALUE=42 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting value in SimpleStorage at $(ADDRESS) to $(VALUE) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "set(uint256)" $(VALUE) \
		--rpc-url $(ACTIVE_RPC) \
		$(SENDER_FLAG) \
		--legacy

get-storage: ## Get the stored value from SimpleStorage (usage: make get-storage ADDRESS=0x... [NETWORK=testnet])
	@cast call $(ADDRESS) "get()(uint256)" \
		--rpc-url $(ACTIVE_RPC)

# --- Uniswap & Fork Interactions ---

fork-start: ## Start a local Anvil node forking Robinhood Chain Mainnet (runs in foreground)
	@echo "Starting Anvil fork of Robinhood Chain Mainnet..."
	anvil --fork-url https://rpc.mainnet.chain.robinhood.com --chain-id 4663

uniswap-interact: ## Interact with Uniswap V2/V3 (usage: make uniswap-interact ACTION=v2_swap NETWORK=fork [AMOUNT_A=100] [AMOUNT_B=1] [TOKEN_A=0x...] [TOKEN_B=0x...] [ACCOUNT=mywallet])
	@echo "Executing Uniswap V2/V3 interactions: ACTION=$(ACTION) on NETWORK=$(NETWORK)..."
	forge script script/UniswapInteractions.s.sol:UniswapInteractions \
		--rpc-url $(ACTIVE_RPC) \
		--broadcast \
		--legacy \
		--gas-estimate-multiplier 200 \
		$(SENDER_FLAG)


uniswap-swap: ## Swap tokens on Uniswap V2 or V3 (usage: make uniswap-swap [ACTION=v2_swap/v3_swap] [AMOUNT_A=10ether] [TOKEN_A=0x...] [TOKEN_B=0x...] [NETWORK=fork])
	@$(MAKE) uniswap-interact ACTION=$(if $(ACTION),$(ACTION),v2_swap) AMOUNT_A=$(AMOUNT_A) TOKEN_A=$(TOKEN_A) TOKEN_B=$(TOKEN_B) V3_FEE=$(V3_FEE) NETWORK=$(NETWORK)

uniswap-add-lp: ## Add liquidity to Uniswap V2 or V3 (usage: make uniswap-add-lp [ACTION=v2_add_lp/v3_add_lp] [AMOUNT_A=100ether] [AMOUNT_B=1ether] [TOKEN_A=0x...] [TOKEN_B=0x...] [NETWORK=fork])
	@$(MAKE) uniswap-interact ACTION=$(if $(ACTION),$(ACTION),v2_add_lp) AMOUNT_A=$(AMOUNT_A) AMOUNT_B=$(AMOUNT_B) TOKEN_A=$(TOKEN_A) TOKEN_B=$(TOKEN_B) V3_FEE=$(V3_FEE) NETWORK=$(NETWORK)