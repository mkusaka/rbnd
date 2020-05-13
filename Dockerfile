# syntax = docker/dockerfile:experimental
FROM ubuntu:bionic

ARG APT_MIRROR=JP
ARG RUBY_VERSION=2.5.7
ARG NODE_VERSION=12.16.3
ARG YARN_VERSION=1.22.4
ARG DOCKER_VERSION=5:19.03.5~3-0~ubuntu-bionic
ARG COMPOSE_VERSION=1.25.3
ARG DOCKERIZE_VERSION=v0.6.1

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i'~' -e "s|http://archive.ubuntu.com/ubuntu|mirror://mirrors.ubuntu.com/${APT_MIRROR}.txt|g" /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    gnupg-agent \
    software-properties-common \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
 && add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
 && curl --silent --location --fail --retry 3 https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
 && add-apt-repository -y "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" \
 && rm -rfv /tmp/*
RUN apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    bison \
    build-essential \
    bzip2 \
    containerd.io \
    docker-ce-cli="${DOCKER_VERSION}" \
    docker-ce="${DOCKER_VERSION}" \
    dpkg-dev \
    fonts-noto \
    fonts-noto-cjk \
    git-core \
    google-chrome-stable \
    gzip \
    jq \
    libcurl4-openssl-dev \
    libffi-dev \
    libgdbm-dev \
    libgdbm5 \
    libncurses5-dev \
    libpq-dev \
    libreadline6-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    locales \
    openssh-client \
    postgresql-client \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    sudo \
    tar \
    tzdata \
    unzip \
    xvfb \
    zip \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Use unicode
RUN locale-gen en_US.UTF-8

# install docker compose
RUN COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
 && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/docker-compose "${COMPOSE_URL}" \
 && chmod +x /usr/bin/docker-compose \
 && docker-compose version

# install dockerize
RUN DOCKERIZE_URL="https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz" \
 && curl --silent --show-error --location --fail --retry 3 "${DOCKERIZE_URL}" | tar -xzf - -C /usr/bin \
 && dockerize --version

# install chromedriver
RUN CHROMEDRIVER_RELEASE=$(curl --silent --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
 && CHROMEDRIVER_URL="http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_RELEASE}/chromedriver_linux64.zip" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "${CHROMEDRIVER_URL}" \
 && cd /tmp \
 && unzip chromedriver_linux64.zip \
 && rm -rf chromedriver_linux64.zip \
 && mv chromedriver /usr/local/bin/chromedriver \
 && chmod +x /usr/local/bin/chromedriver \
 && chromedriver --version

RUN groupadd --gid 3434 circleci \
 && useradd --uid 3434 --gid circleci --shell /bin/bash --create-home circleci \
 && echo 'circleci ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-circleci \
 && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

# start xvfb automatically to avoid needing to express in circle.yml
RUN (echo '#!/bin/sh'; \
    echo 'Xvfb :99 -screen 0 1280x1024x24 &'; \
    echo 'exec "$@"') > /docker-entrypoint.sh \
 && chmod +x /docker-entrypoint.sh

# ensure that the build agent doesn't override the entrypoint
LABEL com.circleci.preserve-entrypoint=true
ENTRYPOINT ["/docker-entrypoint.sh"]

ENV DISPLAY=:99 \
    LANG=en_US.UTF-8 \
    PATH=/home/circleci/.yarn/bin:/home/circleci/.config/yarn/global/node_modules/.bin:/home/circleci/.nodenv/shims:/home/circleci/.nodenv/bin:/home/circleci/.rbenv/shims:/home/circleci/.rbenv/bin:/home/circleci/.local/bin:$PATH
USER circleci

RUN pip3 install --upgrade --user awscli
RUN aws --version
RUN pip3 install --upgrade --user awsebcli
RUN eb --version

RUN git clone --depth 1 https://github.com/nodenv/nodenv.git ~/.nodenv
RUN git clone --depth 1 https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build
RUN nodenv install "${NODE_VERSION}"
RUN nodenv global "${NODE_VERSION}"
RUN node --version
RUN curl --silent --location --fail --retry 3 https://yarnpkg.com/install.sh | bash -s -- --version "${YARN_VERSION}"
RUN yarn --version

RUN git clone --depth 1 https://github.com/rbenv/rbenv.git ~/.rbenv
RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN echo "gem: --no-document" > ~/.gemrc
RUN MAKE_OPTS=-j2 RUBY_CONFIGURE_OPTS=--disable-install-doc rbenv install "${RUBY_VERSION}"
RUN rbenv global "${RUBY_VERSION}" \
RUN ruby --version
RUN gem update --system
RUN gem update --force
RUN rm $(gem env gemdir)/cache/*.gem
RUN gem --version
RUN gem install bundler
RUN bundler --version
RUN bundle config set --global auto_config_jobs true \
 && bundle config set --global clean true \
 && bundle config set --global allow_offline_install true
RUN sudo rm -rf /tmp/*
CMD ["/bin/bash"]
