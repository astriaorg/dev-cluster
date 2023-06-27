set -o errexit -o nounset -o pipefail

export P2P_NETWORK=arabica
export NODE_TYPE=light
exec celestia light start \
    --core.ip "$core_ip" \
    --gateway --gateway.addr "$gateway_addr" --gateway.port "$gateway_port" \
    --p2p.network arabica
