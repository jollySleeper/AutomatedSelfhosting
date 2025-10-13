#!/bin/sh

# echo -e "\n-----++++ Installing AdGuardHome +++++-----"
#
# if [[ -f /opt/AdGuardHome/AdGuardHome ]]; then
#     GIT_URL="https://github.com"
#     REPO_PATH="AdguardTeam/AdGuardHome"
#     REPO_URL="$GIT_URL/$REPO_PATH"
#
#     LATEST_RELEASE_ASSETS_URL=$(wget -q -O - "$REPO_URL/releases/latest" | grep -o "$REPO_URL/releases/expanded_assets/.*$" | cut -d '"' -f 1)
#     echo "-> Latest Release All Assets URL => $LATEST_RELEASE_ASSETS_URL"
#
#     ASSET_URL=$(wget -q -O - "$LATEST_RELEASE_ASSETS_URL" | grep -o "/$REPO_PATH/releases/download/.*linux_arm64.tar.gz")
#     GIT_ASSET_URL="$GIT_URL$ASSET_URL"
#     echo "-> Lastest Release arm64 Asset URL => $GIT_ASSET_URL"
#
#     echo "-> Downloading Latest AdGuardHome"
#     wget -O '/opt/adguardhome_latest.tar.gz' "$GIT_ASSET_URL"
#     echo "-> Extracting AdGuardHome"
#     tar -C '/opt/' -xvf '/opt/adguardhome_latest.tar.gz'
#     rm '/opt/adguardhome_latest.tar.gz'
# fi
#
# echo -e "\n-----++++ Starting AdGuardHome +++++-----"
# if [[ -f "/opt/AdGuardHome/AdGuardHome" ]]; then
#     echo "-> Copying Config Directory"
#     if [[ -d '/tmp/AdGuardHome/conf' ]]; then
#         cp -r /tmp/AdGuardHome/conf /opt/AdGuardHome/.
#     else
#         echo "Config Directory Not Found"
#     fi
#
#     echo "-> Copying DB Directory"
#     if [[ -d '/tmp/AdGuardHome/work' ]]; then
#         cp -r /tmp/AdGuardHome/work /opt/AdGuardHome/.
#     else
#         echo "DB Directory Not Found"
#     fi
#
#     echo "-> Starting in BackGround"
#     /opt/AdGuardHome/AdGuardHome -c /opt/AdGuardHome/conf/AdGuardHome.yaml -w /opt/AdGuardHome/work &
# else
#     echo "-> Binary File Not Found. Can't Start AGH"
# fi
#
# sleep 5
echo -e "\n-----++++ Starting TailScale +++++-----"
/usr/local/bin/containerboot
