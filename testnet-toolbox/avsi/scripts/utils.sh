set -x

function load_defaults {
  export PELLDVS_HOME=${PELLDVS_HOME:-/root/.pelldvs}
  export ETH_RPC_URL=${ETH_RPC_URL:-http://eth:8545}
  export ETH_WS_URL=${ETH_WS_URL:-ws://eth:8545}
  export NETWORK=${NETWORK:-bsc-testnet}
  export CHAIN_ID=${CHAIN_ID:-97}
  export HARDHAT_DVS_PATH="deployments/$NETWORK"
  export ROOT_ADDRESS=""
}

function fetch_pell_address {
  KEY=$1
  curl -s https://raw.githubusercontent.com/0xPellNetwork/network-config/refs/heads/main/testnet/system_contract.json | jq -r ".$KEY"
}

# fetch_dvs_address_by_network NETWORK KEY BRANCH
function fetch_dvs_address_by_network() {
  NETWORK=$1
  KEY=$2
  BRANCH=$3
  if [ -z "$BRANCH" ]; then
    BRANCH="main"
  fi
  curl https://raw.githubusercontent.com/IntelliXLabs/network-config/refs/heads/$BRANCH/testnet/$NETWORK/contracts.json | jq -r ".$KEY"
}

# fetch_dvs_address_for_sepolia KEY BRANCH
function fetch_dvs_address_for_sepolia() {
  fetch_dvs_address_by_network "sepolia" "$1" "$2"
}

# fetch_dvs_address_for_bsc_testnet KEY BRANCH
function fetch_dvs_address_for_bsc_testnet() {
  fetch_dvs_address_by_network "bsc-testnet" "$1" "$2"
}

function must_not_empty() {
  name=$1
  var=$2
  # trim space and tabs
  var="${var//[[:blank:]]/}"
  if [ -z "$var" ]; then
      echo "$name value cant be empty"
      exit 1
  fi
}



load_defaults
