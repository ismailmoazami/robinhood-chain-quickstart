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
else
	ACTIVE_RPC          := $(TESTNET_RPC)
	ACTIVE_CHAIN        := $(TESTNET_CHAIN)
	ACTIVE_VERIFIER_URL := $(TESTNET_VERIFIER_URL)
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
		--account $(ACCOUNT) \
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

mint: ## Mint ERC20 tokens (usage: make mint ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Minting $(AMOUNT) tokens to $(TO) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "mint(address,uint256)" $(TO) $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

burn: ## Burn ERC20 tokens (usage: make burn ADDRESS=0x... AMOUNT=1000000000000000000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Burning $(AMOUNT) tokens on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "burn(uint256)" $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

balance: ## Check ERC20 token balance (usage: make balance ADDRESS=0x... USER=0x... [NETWORK=testnet])
	@cast call $(ADDRESS) "balanceOf(address)(uint256)" $(USER) \
		--rpc-url $(ACTIVE_RPC)

# --- NFT Interactions ---

mint-nft: ## Mint an NFT (usage: make mint-nft ADDRESS=0x... TO=0x... [VALUE=0.001ether] [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Minting NFT to $(TO) on $(NETWORK) using account $(ACCOUNT) with payment $(VALUE)..."
	cast send $(ADDRESS) "mintNFT(address)" $(TO) \
		--value $(VALUE) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

set-base-uri: ## Set NFT base URI (usage: make set-base-uri ADDRESS=0x... URI=ipfs://... [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting base URI of $(ADDRESS) to $(URI) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "setBaseURI(string)" $(URI) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

# --- Simple RWA Interactions ---

deploy-rwa: ## Deploy SimpleRWA (usage: make deploy-rwa [NETWORK=testnet] [ACCOUNT=mywallet])
	@$(MAKE) deploy SCRIPT=DeployRwa CONTRACT=DeployScript NETWORK=$(NETWORK) ACCOUNT=$(ACCOUNT)

mint-rwa: ## Mint SimpleRWA tokens (usage: make mint-rwa ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Minting $(AMOUNT) tokens to $(TO) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "mint(address,uint256)" $(TO) $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

set-eligibility: ## Set eligibility of an address (usage: make set-eligibility ADDRESS=0x... USER=0x... ELIGIBLE=true [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting eligibility of $(USER) to $(ELIGIBLE) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "setEligibility(address,bool)" $(USER) $(ELIGIBLE) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

set-price: ## Set reference price per share in cents (usage: make set-price ADDRESS=0x... PRICE=15000 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting price per share of $(ADDRESS) to $(PRICE) cents on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "setPricePerShareCents(uint256)" $(PRICE) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

# --- Simple Storage Interactions ---

deploy-storage: ## Deploy SimpleStorage (usage: make deploy-storage [NETWORK=testnet] [ACCOUNT=mywallet])
	@$(MAKE) deploy SCRIPT=DeploySimpleStorage CONTRACT=DeployScript NETWORK=$(NETWORK) ACCOUNT=$(ACCOUNT)

set-storage: ## Set a value in SimpleStorage (usage: make set-storage ADDRESS=0x... VALUE=42 [NETWORK=testnet] [ACCOUNT=mywallet])
	@echo "Setting value in SimpleStorage at $(ADDRESS) to $(VALUE) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "set(uint256)" $(VALUE) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

get-storage: ## Get the stored value from SimpleStorage (usage: make get-storage ADDRESS=0x... [NETWORK=testnet])
	@cast call $(ADDRESS) "get()(uint256)" \
		--rpc-url $(ACTIVE_RPC)