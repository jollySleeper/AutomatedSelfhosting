#!/bin/sh

GIT_URL="https://github.com"
REPO_PATH="zyachel/libremdb"
REPO_URL="$GIT_URL/$REPO_PATH"
   
LATEST_RELEASE_ASSETS_URL=$(wget -q -O - "$REPO_URL/releases/latest" | grep -o "$REPO_URL/releases/expanded_assets/.*$" | cut -d '"' -f 1)
echo "-> Latest Release All Assets URL => $LATEST_RELEASE_ASSETS_URL"

# https://github.com/zyachel/libremdb/archive/refs/tags/v3.4.0.tar.gz
ASSET_URL=$(wget -q -O - "$LATEST_RELEASE_ASSETS_URL" | grep -o "/$REPO_PATH/archive/refs/tags/.*.tar.gz")
GIT_ASSET_URL="$GIT_URL$ASSET_URL"
echo "-> Lastest Release Source Code URL => $GIT_ASSET_URL"

echo "-> Downloading Latest LibreMDB Source"
wget -O '/tmp/libremdb-source.tar.gz' "$GIT_ASSET_URL"
echo "-> Extracting LibreMDB Source"
tar -C '/tmp/' -xvf '/tmp/libremdb-source.tar.gz'
rm '/tmp/libremdb-source.tar.gz'
cd "/tmp/$(ls /tmp | grep -i 'libre')"
cp -r * /opt/app
