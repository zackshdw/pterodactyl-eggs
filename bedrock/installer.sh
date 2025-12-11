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
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -d "worlds" ]; then
    echo -e "\nBacking Up World Data"
    WORLD_BACKUP="worlds_backup_${TIMESTAMP}.tar.gz"
    tar -czf "$WORLD_BACKUP" worlds/
    
    if [ -f "$WORLD_BACKUP" ]; then
        echo "    - World Backup Created: $WORLD_BACKUP"
    else
        echo "Warning: World Backup Failed"
    fi
fi

CONFIG_BACKED_UP=false
if [ -f server.properties ] || [ -f permissions.json ] || [ -f allowlist.json ]; then
    echo -e "\nBacking Up Config Files"
    rm -f *.bak
    
    if [ -f server.properties ]; then
        mv server.properties server.properties.bak
        echo "    - Backed Up: server.properties"
    fi
    
    if [ -f permissions.json ]; then
        mv permissions.json permissions.json.bak
        echo "    - Backed Up: permissions.json"
    fi
    
    if [ -f allowlist.json ]; then
        mv allowlist.json allowlist.json.bak
        echo "    - Backed Up: allowlist.json"
    fi
    
    CONFIG_BACKED_UP=true
fi

echo -e "\nDownloading Bedrock Server Version: $BEDROCK_VERSION"
echo -e "Download URL: $DOWNLOAD_URL"
wget -O "$DOWNLOAD_FILE" "$DOWNLOAD_URL"

if [ ! -f "$DOWNLOAD_FILE" ] || [ ! -s "$DOWNLOAD_FILE" ]; then
    echo "Error: Download Failed Or File Is Empty"
    
    if [[ "$DOWNLOAD_URL" == *"$CDN_ROOT"* ]]; then
        echo "Attempting Fallback Download From minecraft.net"
        FALLBACK_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${BEDROCK_VERSION}.zip"
        echo -e "Fallback URL: $FALLBACK_URL"
        wget -O "$DOWNLOAD_FILE" "$FALLBACK_URL"
        
        if [ ! -f "$DOWNLOAD_FILE" ] || [ ! -s "$DOWNLOAD_FILE" ]; then
            echo "Error: Fallback Download Also Failed"
            exit 1
        fi
        echo "Fallback Download Successful"
    else
        exit 1
    fi
fi

echo -e "\nUnpacking Server Files"
unzip -o "$DOWNLOAD_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed To Unzip File"
    exit 1
fi

echo -e "\nCleaning Up After Installing"
rm -f "$DOWNLOAD_FILE"

if [ "$CONFIG_BACKED_UP" = true ]; then
    echo -e "\n    - Restoring Backup Config Files"
    
    if [ -f server.properties.bak ]; then
        mv -f server.properties.bak server.properties
        echo "    - Restored: server.properties"
    fi
    
    if [ -f permissions.json.bak ]; then
        mv -f permissions.json.bak permissions.json
        echo "    - Restored: permissions.json"
    fi
    
    if [ -f allowlist.json.bak ]; then
        mv -f allowlist.json.bak allowlist.json
        echo "    - Restored: allowlist.json"
    fi
fi

if [ -f "$WORLD_BACKUP" ]; then
    echo -e "\nRestoring World Data From Backup"
    rm -rf worlds/
    tar -xzf "$WORLD_BACKUP"
    
    if [ -d "worlds" ]; then
        echo "    - World Data Restored Successfully"
    else
        echo "Warning: World Restore Failed"
    fi
fi

chmod +x bedrock_server
echo -e "\nInstall Completed"