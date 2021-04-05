#!/bin/bash
LAT_V="$(wget -qO- https://api.github.com/repos/TES3MP/openmw-tes3mp/releases | jq -r '.[0].tag_name')"
CUR_V="$(ls -l ${DATA_DIR}/openmwtes3mp-* 2>/dev/null | awk '{print $9}' | cut -d '-' -f2-)"

if [ -z $LAT_V ]; then
    if [ -z $CUR_V ]; then
        echo "---Can't get latest version of OpenMW-TES3MP, putting container into sleep mode!---"
        sleep infinity
    else
        echo "---Can't get latest version of OpenMW-TES3MP, falling back to v$CUR_V---"
        LAT_V=$CUR_V
    fi
fi

if [ "$GAME_V" == "latest" ]; then
    GAME_V="${LAT_V}"
fi

if [ -f ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz ]; then
	rm -rf ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz
fi

echo "---Version Check---"
if [ -z "$CUR_V" ]; then
    echo "---OpenMW-TES3MP not found, downloading and installing v$GAME_V...---"
    DL_URL="$(wget -qO- https://api.github.com/repos/TES3MP/openmw-tes3mp/releases/tags/${GAME_V} | jq -r '.assets' | grep "browser_download_url" | grep "server" | grep "Linux-x86_64" | cut -d '"' -f4)"
    if [ -z "$DL_URL" ]; then
        echo "---Something went wrong, can't get download URL of OpenMW-TES3MP Server, putting container into sleep mode!---"
        sleep infinity
    fi
    cd ${DATA_DIR}
    if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz "$DL_URL" ; then
        echo "---Successfully downloaded OpenMW-TES3MP v$GAME_V---"
    else
        echo "---Something went wrong, can't download OpenMW-TES3MP v$GAME_V, putting container into sleep mode!---"
        sleep infinity
    fi
    mkdir -p ${DATA_DIR}/TES3MP-Server
    tar -C ${DATA_DIR}/TES3MP-Server --strip-components=1 -xf ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz
	touch ${DATA_DIR}/openmwtes3mp-$GAME_V
    rm ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz
elif [ "$CUR_V" != "$GAME_V" ]; then
    echo "---Version missmatch, installed v$CUR_V, downloading and installing v$GAME_V...---"
    DL_URL="$(wget -qO- https://api.github.com/repos/TES3MP/openmw-tes3mp/releases/tags/${GAME_V} | jq -r '.assets' | grep "browser_download_url" | grep "server" | grep "Linux-x86_64" | cut -d '"' -f4)"
    if [ -z "$DL_URL" ]; then
        echo "---Something went wrong, can't get download URL of OpenMW-TES3MP Server, putting container into sleep mode!---"
        sleep infinity
    fi
    cd ${DATA_DIR}/TES3MP-Server
    mkdir /tmp/backup
    cp -R *.cfg CoreScripts/ resources/ /tmp/backup/
    rm -rf openmwtes3mp-*
    if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz "$DL_URL" ; then
        echo "---Successfully downloaded OpenMW-TES3MP v$GAME_V---"
    else
        echo "---Something went wrong, can't download OpenMW-TES3MP v$GAME_V, putting container into sleep mode!---"
        sleep infinity
    fi
    mkdir -p ${DATA_DIR}/TES3MP-Server
    tar -C ${DATA_DIR}/TES3MP-Server --strip-components=1 -xf ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz
	touch ${DATA_DIR}/openmwtes3mp-$GAME_V
    cp -R /tmp/backup/* ${DATA_DIR}/TES3MP-Server/
    rm ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz /tmp/backup
elif [ "$CUR_V" == "$GAME_V" ]; then
    echo "---OpenMW-TES3MP v$GAME_V up-to-date---"
fi

echo "---Preparing Server---"
if [ "$(cat ${DATA_DIR}/TES3MP-Server/tes3mp-server-default.cfg | grep "hostname = My TES3MP server")" ]; then
    sed -i '/hostname = My TES3MP server/c\hostname = TES3MP Docker Server\' ${DATA_DIR}/TES3MP-Server/tes3mp-server-default.cfg
    sed -i '/password =/c\password = Docker\' ${DATA_DIR}/TES3MP-Server/tes3mp-server-default.cfg
fi
if [ "$(cat ${DATA_DIR}/TES3MP-Server/CoreScripts/data/requiredDataFiles.json | grep '    {"Morrowind.esm": \["0x7B6AF5B9", "0x34282D67"\]},')" ]; then
    sed -i '/    {"Morrowind.esm": \["0x7B6AF5B9", "0x34282D67"\]},/c\    {"Morrowind.esm": ["0x7B6AF5B9", "0x34282D67", "0x5F9766E6"]},\' ${DATA_DIR}/TES3MP-Server/CoreScripts/data/requiredDataFiles.json
    sed -i '/    {"Tribunal.esm": \["0xF481F334", "0x211329EF"\]},/c\    {"Tribunal.esm": ["0xF481F334", "0x211329EF", "0x7C19567D"]},\' ${DATA_DIR}/TES3MP-Server/CoreScripts/data/requiredDataFiles.json
    sed -i '/    {"Bloodmoon.esm": \["0x43DD2132", "0x9EB62F26"\]}/c\    {"Bloodmoon.esm": ["0x43DD2132", "0x9EB62F26", "0xF6FC8BE4"]}\' ${DATA_DIR}/TES3MP-Server/CoreScripts/data/requiredDataFiles.json
fi
chmod -R ${DATA_PERM} ${DATA_DIR}

echo "---Starting Server---"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${DATA_DIR}/TES3MP-Server/lib
cd ${DATA_DIR}/TES3MP-Server
${DATA_DIR}/TES3MP-Server/tes3mp-server.x86_64 ${GAME_PARAMS}
