.PHONY: build deploy deploy-testnet verify verify-testnet clean help mint burn balance

# Include .env file
-include .env
export

# Default configuration
NETWORK ?= testnet
ACCOUNT ?= mywallet

# Robinhood Chain Testnet
TESTNET_RPC    ?= https://rpc.testnet.chain.robinhood.com
TESTNET_CHAIN  ?= 46630
TESTNET_VERIFIER_URL ?= https://explorer.testnet.chain.robinhood.com/api/

# Robinhood Chain Mainnet
MAINNET_RPC    ?= https://rpc.mainnet.chain.robinhood.com
MAINNET_CHAIN  ?= 4663
MAINNET_VERIFIER_URL ?= https://robinhoodchain.blockscout.com/api/

# Set active RPC based on the specified NETWORK
ifeq ($(NETWORK),mainnet)
	ACTIVE_RPC := $(MAINNET_RPC)
else
	ACTIVE_RPC := $(TESTNET_RPC)
endif

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Compile the contracts
	forge build

clean: ## Remove build artifacts
	forge clean

# --- Testnet targets ---

deploy-testnet: ## Deploy ERC20Token to Robinhood Chain Testnet
	@echo "Deploying ERC20Token to Robinhood Chain Testnet using account $(ACCOUNT)..."
	forge script script/Deploy.s.sol:DeployScript \
		--rpc-url $(TESTNET_RPC) \
		--account $(ACCOUNT) \
		--broadcast \
		--legacy

verify-testnet: ## Verify ERC20Token on testnet explorer (usage: make verify-testnet ADDRESS=0x...)
	@echo "Verifying ERC20Token on testnet Blockscout..."
	forge verify-contract $(ADDRESS) \
		src/ERC20Token.sol:ERC20Token \
		--chain-id $(TESTNET_CHAIN) \
		--rpc-url $(TESTNET_RPC) \
		--verifier blockscout \
		--verifier-url $(TESTNET_VERIFIER_URL)

# --- Mainnet targets ---

deploy-mainnet: ## Deploy ERC20Token to Robinhood Chain Mainnet
	@echo "Deploying ERC20Token to Robinhood Chain Mainnet using account $(ACCOUNT)..."
	forge script script/Deploy.s.sol:DeployScript \
		--rpc-url $(MAINNET_RPC) \
		--account $(ACCOUNT) \
		--broadcast \
		--legacy

verify-mainnet: ## Verify ERC20Token on mainnet explorer (usage: make verify-mainnet ADDRESS=0x...)
	@echo "Verifying ERC20Token on mainnet Blockscout..."
	forge verify-contract $(ADDRESS) \
		src/ERC20Token.sol:ERC20Token \
		--chain-id $(MAINNET_CHAIN) \
		--rpc-url $(MAINNET_RPC) \
		--verifier blockscout \
		--verifier-url $(MAINNET_VERIFIER_URL)

# --- Default deploy (testnet) ---

deploy: deploy-testnet ## Deploy to testnet by default

# --- Chain Interactions ---

mint: ## Mint tokens (usage: make mint ADDRESS=0x... TO=0x... AMOUNT=1000000000000000000 [NETWORK=testnet/mainnet] [ACCOUNT=mywallet])
	@echo "Minting $(AMOUNT) tokens to $(TO) on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "mint(address,uint256)" $(TO) $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

burn: ## Burn tokens (usage: make burn ADDRESS=0x... AMOUNT=1000000000000000000 [NETWORK=testnet/mainnet] [ACCOUNT=mywallet])
	@echo "Burning $(AMOUNT) tokens on $(NETWORK) using account $(ACCOUNT)..."
	cast send $(ADDRESS) "burn(uint256)" $(AMOUNT) \
		--rpc-url $(ACTIVE_RPC) \
		--account $(ACCOUNT) \
		--legacy

balance: ## Check token balance (usage: make balance ADDRESS=0x... USER=0x... [NETWORK=testnet/mainnet])
	@cast call $(ADDRESS) "balanceOf(address)(uint256)" $(USER) \
		--rpc-url $(ACTIVE_RPC)