#!/bin/bash

set -x
set -e

source "$(dirname "$0")/utils.sh"

logt() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

function load_defaults {
  export PELLDVS_HOME=${PELLDVS_HOME:-/root/.pelldvs}
  export INTELLIX_HOME=${INTELLIX_HOME:-/root/.intellix}
  export ETH_RPC_URL=${ETH_RPC_URL}
  export ETH_WS_URL=${ETH_WS_URL}
  export GATEWAY_ADDR=${GATEWAY_ADDR:-gateway:8949}
  export OPERATOR_KEY_NAME=${OPERATOR_KEY_NAME:-operator}
  export OPERATOR_KEY=${OPERATOR_KEY}
  export OPERATOR_KEY_MNEMONIC=${OPERATOR_KEY_MNEMONIC}
  export AGGREGATOR_RPC_URL=${AGGREGATOR_RPC_URL:-aggregator:26653}
  export OPERATOR_RPC_SERVER=${OPERATOR_RPC_SERVER:-avsi:26657}

  export NETWORK=${NETWORK}
  export CHAIN_ID=${CHAIN_ID}
  export HARDHAT_DVS_PATH="deployments/$NETWORK"

  export SEPOLIA_ID=11155111
  export SEPOLIA_RPC_URL=${SEPOLIA_RPC_URL:-https://bsc-testnet.blockpi.network/v1/rpc/public}
  export SEPOLIA_WS_URL=${SEPOLIA_WS_URL}

  export AGGREGATOR_INDEXER_START_HEIGHT=${AGGREGATOR_INDEXER_START_HEIGHT:-0}
  export AGGREGATOR_INDEXER_BATCH_SIZE=${AGGREGATOR_INDEXER_BATCH_SIZE:-100}

  export COSMOS_KEYRING_BACKEND=${COSMOS_KEYRING_BACKEND:-test}
  export COSMOS_CHAIN_ID=${COSMOS_CHAIN_ID:-intellix}
  export COSMOS_NODE_URI=${COSMOS_NODE_URI:-http://abci:26657}

  export COINMARKETCAP_API_KEY=${COINMARKETCAP_API_KEY:-""}
  export API_KEYS_PATH=${API_KEYS_PATH:-"$INTELLIX_HOME/api_keys"}

  export ECC_PRIVATE_KEY=${ECC_PRIVATE_KEY}
  export ECC_PUBLIC_KEY=${ECC_PUBLIC_KEY}
}

function dvs_healthcheck {
  set +e
  while true; do
    curl -s $AGGREGATOR_RPC_URL >/dev/null
    if [ $? -eq 52 ]; then
      echo "DVS RPC port is ready, proceeding to the next step..."
      break
    fi
    echo "DVS RPC port not ready, retrying in 2 seconds..."
    sleep 2
  done
  ## Wait for aggregator to be ready
  sleep 3
  set -e
}

## TODO: move operator config to seperated location
function init_pelldvs_config {
  pelldvs init --home $PELLDVS_HOME
  update-config() {
    KEY="$1"
    VALUE="$2"
    sed -i "s|${KEY} = \".*\"|${KEY} = \"${VALUE}\"|" ~/.pelldvs/config/config.toml
  }

  ## update config
  ## FIXME: don't use absolute path for key
  update-config operator_bls_private_key_store_path "$PELLDVS_HOME/keys/$OPERATOR_KEY_NAME.bls.key.json"
  update-config operator_ecdsa_private_key_store_path "$PELLDVS_HOME/keys/$OPERATOR_KEY_NAME.ecdsa.key.json"
  update-config interactor_config_path "$PELLDVS_HOME/config/interactor_config.json"
  update-config aggregator_rpc_url "$AGGREGATOR_RPC_URL"

  REGISTRY_ROUTER_FACTORY_ADDRESS=$(fetch_pell_address "registry_router_factory")
  PELL_DELEGATION_MNAGER=$(fetch_pell_address "delegation_manager_proxy")
  PELL_DVS_DIRECTORY=$(fetch_pell_address "dvs_directory_proxy")

  # DVS contracts addresses
  REGISTRY_ROUTER_ADDRESS=$(fetch_dvs_address_for_sepolia "registry_router_proxy")
  SEPOLIA_DVS_CENTRAL_SCHEDULER=$(fetch_dvs_address_for_sepolia "central_scheduler_proxy")
  SEPOLIA_DVS_OPERATOR_KEY_MANAGER=$(fetch_dvs_address_for_sepolia "operator_key_manager_proxy")
  SEPOLIA_DVS_OPERATOR_INFO_PROVIDER=$(fetch_dvs_address_for_sepolia "operator_info_provider")
  SEPOLIA_DVS_OPERATOR_INDEX_MANAGER=$(fetch_dvs_address_for_sepolia "operator_index_manager_proxy")

  must_not_empty "REGISTRY_ROUTER_FACTORY_ADDRESS" $REGISTRY_ROUTER_FACTORY_ADDRESS
  must_not_empty "PELL_DELEGATION_MNAGER" $PELL_DELEGATION_MNAGER
  must_not_empty "PELL_DVS_DIRECTORY" $PELL_DVS_DIRECTORY

  must_not_empty "REGISTRY_ROUTER_ADDRESS" $REGISTRY_ROUTER_ADDRESS
  must_not_empty "SEPOLIA_DVS_CENTRAL_SCHEDULER" $SEPOLIA_DVS_CENTRAL_SCHEDULER
  must_not_empty "SEPOLIA_DVS_OPERATOR_KEY_MANAGER" $SEPOLIA_DVS_OPERATOR_KEY_MANAGER
  must_not_empty "SEPOLIA_DVS_OPERATOR_INFO_PROVIDER" $SEPOLIA_DVS_OPERATOR_INFO_PROVIDER
  must_not_empty "SEPOLIA_DVS_OPERATOR_INDEX_MANAGER" $SEPOLIA_DVS_OPERATOR_INDEX_MANAGER

  must_not_empty "ETH_RPC_URL" $ETH_RPC_URL
  must_not_empty "CHAIN_ID" $CHAIN_ID
  must_not_empty "AGGREGATOR_INDEXER_START_HEIGHT" $AGGREGATOR_INDEXER_START_HEIGHT
  must_not_empty "AGGREGATOR_INDEXER_BATCH_SIZE" $AGGREGATOR_INDEXER_BATCH_SIZE
  must_not_empty "COSMOS_NODE_URI" $COSMOS_NODE_URI
  must_not_empty "COSMOS_CHAIN_ID" $COSMOS_CHAIN_ID
  must_not_empty "ECC_PUBLIC_KEY" $ECC_PUBLIC_KEY

  cat <<EOF > $PELLDVS_HOME/config/interactor_config.json
{
    "rpc_url": "$ETH_RPC_URL",
    "chain_id": $CHAIN_ID,
    "contract_config": {
      "indexer_start_height": $AGGREGATOR_INDEXER_START_HEIGHT,
      "indexer_batch_size": $AGGREGATOR_INDEXER_BATCH_SIZE,
      "pell_registry_router_factory": "$REGISTRY_ROUTER_FACTORY_ADDRESS",
      "pell_dvs_directory": "$PELL_DVS_DIRECTORY",
      "pell_delegation_manager": "$PELL_DELEGATION_MNAGER",
      "pell_registry_router": "$REGISTRY_ROUTER_ADDRESS",
      "dvs_configs": {
        "$SEPOLIA_ID": {
          "chain_id": $SEPOLIA_ID,
          "rpc_url": "$SEPOLIA_RPC_URL",
          "operator_info_provider": "$SEPOLIA_DVS_OPERATOR_INFO_PROVIDER",
          "operator_key_manager": "$SEPOLIA_DVS_OPERATOR_KEY_MANAGER",
          "central_scheduler": "$SEPOLIA_DVS_CENTRAL_SCHEDULER",
          "operator_index_manager": "$SEPOLIA_DVS_OPERATOR_INDEX_MANAGER"
        }
      }
    }
}
EOF

cat $PELLDVS_HOME/config/interactor_config.json
}

function gen_cosmos_key {
  if intellixd keys show $OPERATOR_KEY_NAME --keyring-backend test --home $PELLDVS_HOME; then
    echo "Operator key already exists"
  else
    echo $OPERATOR_KEY_MNEMONIC | intellixd keys add $OPERATOR_KEY_NAME --recover --keyring-backend=test --home $PELLDVS_HOME
  fi

  ## migrate to dvs logic after fix
  export OPERATOR_ADDRESS=$(pelldvs keys show $OPERATOR_KEY_NAME --home $PELLDVS_HOME | awk '/Key content:/{getline; print}' | head -n 1 | jq -r .address)
}

function setup_operator_config {
  gen_cosmos_key
  ## migrate to dvs logic after fix
  export OPERATOR_ADDRESS=$(pelldvs keys show $OPERATOR_KEY_NAME --home $PELLDVS_HOME | awk '/Key content:/{getline; print}' | head -n 1 | jq -r .address)
  ## TODO: use operator key on config.toml and gateway should be on app.toml
  cat <<EOF > $PELLDVS_HOME/config/operator.config.json
{
  "operator_address": "$OPERATOR_ADDRESS",
  "cosmos_node_uri": "$COSMOS_NODE_URI",
  "cosmos_chain_id": "$COSMOS_CHAIN_ID",
  "price_tick_converter_config": {
    "binance": {
      "USD": "USDT"
    },
    "okx": {
      "USD": "USDT"
    },
    "gate": {
      "USD": "USDT"
    }
  },
  "api_key": {
    "coinmarketcap": "$COINMARKETCAP_API_KEY"
  },
  "symbol_list": {
    "crypto": {
      "TON": "USD",
      "BTC": "USD",
      "SAVM": "USD",
      "DOGE": "USD",
      "ORDI": "USD",
      "PEPE": "USD",
      "CAT": "USD",
      "GOAT": "USD",
      "NEIROCTO": "USD",
      "XLM": "USD",
      "XRP": "USD",
      "ACT": "USD",
      "DOGS": "USD",
      "MEME": "USD",
      "BNB": "USD",
      "ETH": "USD",
      "MUBI": "USD",
      "BB": "USD",
      "CATS": "USD",
      "DAI": "USD",
      "LADYS": "USD",
      "SUNDOG": "USD",
      "BAN": "USD",
      "PUSS": "USD",
      "MOODENG": "USD",
      "USDC": "USD",
      "NEIRO": "USD",
      "1000SATS": "USD",
      "NEIROETH": "USD",
      "AUCTION": "USD",
      "WIF": "USD",
      "USDT": "USD",
      "BOME": "USD"
    },
    "a_shares": {
      "1_000001": "CNY",
      "0_399001": "CNY"
    },
    "hk_shares": {
      "100_HSI": "HKD"
    },
    "us_stocks": {
      "MSTR": "USD",
      "BB": "USD",
      "COIN": "USD",
      "NVDA": "USD",
      "TSLA": "USD",
      "PLTR": "USD",
      "AAPL": "USD",
      "AMZN": "USD",
      "GOOGL": "USD"
    }
  },
  "ecc_key_pair": {
    "ecc_private_key_path": "",
    "ecc_public_key": "$ECC_PUBLIC_KEY"
  }
}
EOF

  cat $PELLDVS_HOME/config/operator.config.json
  logt "Operator config created:"

  # set coinmarketcap api key
  COINMARKETCAP_API_KEY=$(echo $COINMARKETCAP_API_KEY | sed 's/^"\(.*\)"$/\1/')

  mkdir -p "$API_KEYS_PATH"
  if [ -n "$COINMARKETCAP_API_KEY" ]; then
    echo "$COINMARKETCAP_API_KEY" > "$API_KEYS_PATH/coinmarketcap.key"
    logt "CoinMarketCap API key configured: $COINMARKETCAP_API_KEY"
  else
    logt "No CoinMarketCap API key provided"
  fi

  logt "API keys path: $API_KEYS_PATH"
}

function start_operator {
  intellixd start-operator --home $PELLDVS_HOME
}

logt "Load Default Values for ENV Vars if not set."
load_defaults

#logt "Check if DVS is ready"
dvs_healthcheck

logt "setup operator key"
source "$(dirname "$0")/setup_operator_key.sh"

logt "init pelldvs config"
init_pelldvs_config

logt "Setup operator config"
setup_operator_config

logt "Starting operator..."
start_operator
