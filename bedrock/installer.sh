#!/bin/bash
apt update
apt install -y zip unzip wget curl jq

if [ ! -d /mnt/server/ ]; then
    mkdir /mnt/server/
fi

cd /mnt/server

if [ -z "${BEDROCK_VERSION}" ] || [ "${BEDROCK_VERSION}" == "latest" ]; then
    echo -e "\n Downloading Latest Bedrock Server"
    
    echo "Fetching Version Information..."
    VERSION_JSON=$(curl -s "https://raw.githubusercontent.com/Bedrock-OSS/BDS-Versions/main/versions.json")
    
    BEDROCK_VERSION=$(echo "$VERSION_JSON" | jq -r '.linux.stable')
    CDN_ROOT=$(echo "$VERSION_JSON" | jq -r '.cdn_root')
    
    if [ -z "$BEDROCK_VERSION" ] || [ "$BEDROCK_VERSION" == "null" ]; then
        echo "Error: Could Not Fetch Version Information"
        exit 1
    fi
    
    DOWNLOAD_URL="${CDN_ROOT}/bin-linux/bedrock-server-${BEDROCK_VERSION}.zip"
else 
    echo -e "\n Downloading ${BEDROCK_VERSION}"
    DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${BEDROCK_VERSION}.zip"
fi

DOWNLOAD_FILE=$(basename "$DOWNLOAD_URL")

echo -e "Backing Up Config Files"
rm -f *.bak
[ -f server.properties ] && cp server.properties server.properties.bak
[ -f permissions.json ] && cp permissions.json permissions.json.bak
[ -f allowlist.json ] && cp allowlist.json allowlist.json.bak

echo -e "Downloading Bedrock Server Version: $BEDROCK_VERSION"
echo -e "Download URL: $DOWNLOAD_URL"

wget -O "$DOWNLOAD_FILE" "$DOWNLOAD_URL"

if [ ! -f "$DOWNLOAD_FILE" ] || [ ! -s "$DOWNLOAD_FILE" ]; then
    echo "Error: Download Failed Or File Is Empty"
    exit 1
fi

echo -e "Unpacking Server Files"
unzip -o "$DOWNLOAD_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed To Unzip File"
    exit 1
fi

echo -e "Cleaning Up After Installing"
rm -f "$DOWNLOAD_FILE"

echo -e "Restoring Backup Config Files"
[ -f server.properties.bak ] && cp -f server.properties.bak server.properties
[ -f permissions.json.bak ] && cp -f permissions.json.bak permissions.json
[ -f allowlist.json.bak ] && cp -f allowlist.json.bak allowlist.json

chmod +x bedrock_server

echo -e "Install Completed"