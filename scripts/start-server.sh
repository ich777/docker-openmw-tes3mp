#!/bin/bash
echo "---Container under construction, sleep zZzZz---"
sleep infinity

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
    cp *.cfg /tmp/backup/
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
    cp /tmp/backup/* ${DATA_DIR}/TES3MP-Server/
    rm ${DATA_DIR}/openmw-tes3mp-v$GAME_V.tar.gz /tmp/backup
elif [ "$CUR_V" == "$GAME_V" ]; then
    echo "---OpenMW-TES3MP v$GAME_V up-to-date---"
fi

echo "---Preparing Server---"
chmod -R ${DATA_PERM} ${DATA_DIR}

echo "---Starting Server---"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${DATA_DIR}/TES3MP-Server/lib
cd ${DATA_DIR}
${DATA_DIR}/TES3MP-Server/tes3mp-server.x86_64
