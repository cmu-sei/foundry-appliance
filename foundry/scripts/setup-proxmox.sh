#! /bin/bash

# Proxmox initialization script. Also sets required TM fields.
# -Sebastian Babon

set -euo pipefail

RUI_CRT=$(< /home/foundry/foundry/certs/host.pem)
RUI_KEY=$(< /home/foundry/foundry/certs/host-key.pem)
PROXMOX_CERTDIR="/etc/pve/nodes/pve"
PROXMOX_HOSTNAME="proxmox.foundry.local"
PROXMOX_USER="root"
HOSTS_FILE="/etc/hosts"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <proxmox-url> <api-key>"
  exit 1
fi

PROXMOX_URL="$1"
PROXMOX_URL=${PROXMOX_URL%/}
PROXMOX_IP=$(echo "$PROXMOX_URL" | sed -E 's~^[a-zA-Z]+://([^:/]+).*~\1~')
API_KEY="$2"

# SDN Zone Creation
SDN_ZONE_NAME="topomojo"
SDN_PLUGIN_TYPE="vxlan"

API_URL="$PROXMOX_URL/api2/json"

read -p "Enter peer IPs (comma-delimited, e.g. 10.0.0.2,10.0.0.3): " PEER_IPS

curl -k -X POST "$API_URL/cluster/sdn/zones" \
  -H "Authorization: PVEAPIToken=$API_KEY" \
  -d "zone=$SDN_ZONE_NAME" \
  -d "type=$SDN_PLUGIN_TYPE" \
  -d "nodes=all" \
  -d "peers=$PEER_IPS"

# Update local /etc/hosts
echo -e "\n*** If prompted, type your SUDO password. ***\n"
if grep -q "${PROXMOX_HOSTNAME}" "${HOSTS_FILE}"; then
  sudo sed -i -r "s/.*(${PROXMOX_HOSTNAME})/${PROXMOX_IP} \1/" "${HOSTS_FILE}"
  echo -e "\n${PROXMOX_HOSTNAME} (${PROXMOX_IP}) updated in ${HOSTS_FILE}"
else
  echo "${PROXMOX_IP} ${PROXMOX_HOSTNAME}" | sudo tee -a "${HOSTS_FILE}" > /dev/null
  echo -e "\n${PROXMOX_HOSTNAME} (${PROXMOX_IP}) added to ${HOSTS_FILE}"
fi

sudo systemctl restart dnsmasq
echo -e "\ndnsmasq restarted."

# Remote Proxmox configuration (nginx, DNS, certs)
ssh "${PROXMOX_USER}@${PROXMOX_HOSTNAME}" << EOF
set -e

hostnamectl set-hostname "${PROXMOX_HOSTNAME}"

echo "${PROXMOX_HOSTNAME}" > /etc/hostname

if grep -q "${PROXMOX_HOSTNAME}" /etc/hosts; then
    sed -i "s/^.*${PROXMOX_HOSTNAME}.*/${PROXMOX_IP} ${PROXMOX_HOSTNAME} proxmox/" /etc/hosts
else
    echo "${PROXMOX_IP} ${PROXMOX_HOSTNAME} proxmox" >> /etc/hosts
fi

hostnamectl

if [ ! -f "${PROXMOX_CERTDIR}/pve-ssl.pem.orig" ]; then
    cp "${PROXMOX_CERTDIR}/pve-ssl.pem" "${PROXMOX_CERTDIR}/pve-ssl.pem.orig"
fi
echo "${RUI_CRT}" > "${PROXMOX_CERTDIR}/pve-ssl.pem"

if [ ! -f "${PROXMOX_CERTDIR}/pve-ssl.key.orig" ]; then
    cp "${PROXMOX_CERTDIR}/pve-ssl.key" "${PROXMOX_CERTDIR}/pve-ssl.key.orig"
fi
echo "${RUI_KEY}" > "${PROXMOX_CERTDIR}/pve-ssl.key"

rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/ceph.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | tee /etc/apt/sources.list.d/pve-no-subscription.list
apt clean

apt update
apt install -y nginx
systemctl enable nginx

rm -f /etc/nginx/sites-enabled/default

cat <<INNER_EOF > /etc/nginx/sites-available/proxmox.conf
upstream proxmox {
    server "$PROXMOX_HOSTNAME";
}

server {
    listen 80 default_server;
    rewrite ^(.*) https://\$host\$1 permanent;
}

server {
    listen 443;
    server_name _;

    ssl on;
    ssl_certificate /etc/pve/local/pve-ssl.pem;
    ssl_certificate_key /etc/pve/local/pve-ssl.key;
    proxy_redirect off;

    location ~ /api2/json/nodes/.+/qemu/.+/vncwebsocket.* {
        proxy_set_header "Authorization" 'PVEAPIToken=$API_KEY';
        proxy_http_version 1.1;
        proxy_set_header Connection "upgrade";
        proxy_pass https://localhost:8006;
        proxy_buffering off;
        client_max_body_size 0;
        proxy_connect_timeout 3600s;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        send_timeout 3600s;
    }

    location / {
        proxy_http_version 1.1;
        proxy_set_header Connection "upgrade";
        proxy_pass https://localhost:8006;
        proxy_buffering off;
        client_max_body_size 0;
        proxy_connect_timeout 3600s;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        send_timeout 3600s;
    }
}

INNER_EOF

ln -sf /etc/nginx/sites-available/proxmox.conf /etc/nginx/sites-enabled/proxmox.conf

nginx -t
systemctl reload nginx
systemctl restart pveproxy pvedaemon
EOF

sed -i "s|<PVE_URL>|$PROXMOX_URL|g" /home/foundry/foundry/topomojo.values.yaml
sed -i "s|<ACCESS_TOKEN>|$API_KEY|g" /home/foundry/foundry/topomojo.values.yaml
sed -i "s|<SDN_ZONE>|$SDN_ZONE_NAME|g" /home/foundry/foundry/topomojo.values.yaml

helm upgrade --install --wait -n foundry -f topomojo.values.yaml topomojo sei/topomojo --version 0.4.5