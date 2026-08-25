FROM ubuntu:18.04

ARG USER_ID=1001
ARG GROUP_ID=1001

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Etc/UTC

RUN echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' \
	| debconf-set-selections \
	&& echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections \
	&& echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		git \
		git-lfs \
		locales \
		lsb-release \
		python \
		python-pip \
		python-setuptools \
		sudo \
		unzip \
		wget \
		xz-utils \
		zip \
	&& locale-gen en_US.UTF-8 \
	&& curl -fsSL \
		'https://chromium.googlesource.com/chromium/src/+/refs/tags/87.0.4280.141/build/install-build-deps.sh?format=TEXT' \
		| base64 --decode > /tmp/install-build-deps.sh \
	&& chmod +x /tmp/install-build-deps.sh \
	&& /tmp/install-build-deps.sh \
		--no-syms --no-prompt --no-chromeos-fonts --no-nacl --arm \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		binutils-aarch64-linux-gnu \
		g++-aarch64-linux-gnu \
		gcc-aarch64-linux-gnu \
		libc6-dev-arm64-cross \
		linux-libc-dev-arm64-cross \
	&& curl -fsSLO \
		https://nodejs.org/dist/v12.18.3/node-v12.18.3-linux-x64.tar.xz \
	&& tar -xJf node-v12.18.3-linux-x64.tar.xz -C /usr/local --strip-components=1 \
	&& rm -f node-v12.18.3-linux-x64.tar.xz /tmp/install-build-deps.sh \
	&& rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${GROUP_ID}" builder \
	&& useradd --uid "${USER_ID}" --gid builder --create-home --shell /bin/bash builder \
	&& echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder

USER builder
WORKDIR /workspace
