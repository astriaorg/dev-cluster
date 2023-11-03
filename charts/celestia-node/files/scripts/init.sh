# $1 argument: celestia-node home directory (default: ~/celestia/.celestia-node)

echo "Init celestia node store folder"

mkdir -p $1/data
mkdir -p $1/keys
