FROM ich777/debian-baseimage

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-openmw-tes3mp"

COPY cjson.tar.gz /tmp/

RUN apt-get update && \
	apt-get -y install --no-install-recommends libluajit-5.1-2 libgl1 lua-cjson jq && \
	tar -C / -xvf /tmp/cjson.tar.gz && \
	rm -rf /tmp/cjson.tar.gz && \
	rm -rf /var/lib/apt/lists/*

ENV DATA_DIR=/openmw
ENV GAME_V="latest"
ENV SRV_NAME="Docker OpenMW"
ENV GAME_PARAMS=""
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="openmw"

RUN mkdir $DATA_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]