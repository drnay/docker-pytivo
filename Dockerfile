FROM linuxserver/ffmpeg

ARG PYTIVO_TAG

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ARG PYTHON_PKG=python3.8
ENV PYTHON_PKG=${PYTHON_PKG}

RUN \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
	curl \
	g++ \
	gcc \
	make \
	jq && \
 apt-get install --no-install-recommends -y \
#	openjdk-11-jre-headless \
	${PYTHON_PKG} \
	python3-pip && \
 echo "**** install tivodecode ****" && \
 TIVODECODE_TARBALL_URL=$(curl -sX GET "https://api.github.com/repos/wmcbrine/tivodecode-ng/releases/latest" \
	| jq -r .tarball_url) && \
 mkdir -p /opt/tivodecode && \
 curl -L ${TIVODECODE_TARBALL_URL} \
	| tar -xz -C /opt/tivodecode --strip-components=1 && \
 cd /opt/tivodecode && \
 ./configure && \
 make && \
 make install && \
 echo "**** install pytivo ****" && \
 if [ -z ${PYTIVO_TAG+x} ]; then \
	PYTIVO_TARBALL_URL=$(curl -sX GET "https://api.github.com/repos/mlippert/pytivo/tags?per_page=1" \
	| jq -r .[0].tarball_url); \
 else \
	PYTIVO_TARBALL_URL="https://api.github.com/repos/mlippert/pytivo/tarball/refs/tags/${PYTIVO_TAG}"; \
 fi && \
 mkdir -p /app/pytivo && \
 curl -L ${PYTIVO_TARBALL_URL} \
	| tar -xz -C /app/pytivo --strip-components=1 && \
 chmod +x /app/pytivo/pyTivo.py && \
 sed -i '/^[^#]*ffmpeg/s/^/#/' /app/pytivo/pyTivo.conf.dist && \
 sed -i '\%^[^#]*/home/armooo%Is%/home/armooo/Videos%/Videos%I' /app/pytivo/pyTivo.conf.dist && \
 mkdir -p /config && \
 cp /app/pytivo/pyTivo.conf.dist /config/pyTivo.conf && \
 echo "**** install pytivo requirements ****" && \
 ${PYTHON_PKG} -m pip install --upgrade pip && \
 ${PYTHON_PKG} -m pip install -r /app/pytivo/requirements.txt && \
 echo "**** cleanup ****" && \
 apt-get -y purge \
	g++ \
	gcc \
	make \
	jq && \
 apt-get -y autoremove && \
 apt-get -y clean && \
 rm -rf \
	/opt/tivodecode \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 9032
VOLUME /config /Videos

ENTRYPOINT ["/init"]
