set -x

function fetch_pell_address {
  KEY=$1
  curl -s https://raw.githubusercontent.com/0xPellNetwork/network-config/refs/heads/main/testnet/system_contract.json | jq -r ".$KEY"
}

function fetch_dvs_address {
  KEY=$1
  curl -s https://api.github.com/repos/IntelliXLabs/network-config/contents/testnet/price_oracle.json | jq -r ".$KEY"
}

