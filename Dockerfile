FROM ubuntu:bionic

ARG APT_MIRROR=JP
ARG RUBY_VERSION=2.6.3
ARG NODE_VERSION=12.6.0
ARG YARN_VERSION=1.16.0

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i'~' -e "s%http://archive.ubuntu.com/ubuntu%mirror://mirrors.ubuntu.com/${APT_MIRROR}.txt%g" /etc/apt/sources.list \
 && echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90circleci \
 && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90circleci \
 && echo 'APT::Acquire::Queue-Mode "host";' > /etc/apt/apt.conf.d/75download \
 && echo 'APT::Acquire::http::Pipeline-Depth "10";' >> /etc/apt/apt.conf.d/75download \
 && echo 'APT::Acquire::Retries "5";' >> /etc/apt/apt.conf.d/75download \
 && mkdir -p /usr/share/man/man1 \
 && apt-get update \
 && apt-get install --yes --no-install-recommends --auto-remove \
    apt-transport-https \
    autoconf \
    bison \
    build-essential \
    bzip2 \
    ca-certificates \
    curl \
    git \
    git-core \
    gnupg \
    gzip \
    libcurl4-openssl-dev \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    locales \
    mercurial \
    net-tools \
    netcat \
    openjdk-8-jdk \
    openjdk-8-jdk-headless \
    openjdk-8-jre \
    openjdk-8-jre-headless \
    openssh-client \
    parallel \
    postgresql-client \
    python \
    python-dev \
    software-properties-common \
    sqlite3 \
    sudo \
    tar \
    tzdata \
    unzip \
    wget \
    xvfb \
    zip \
    zlib1g-dev \
 && CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb "${CHROME_URL}" \
 && (dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -fy install)  \
 && apt-get install --yes libgconf-2-4 \
 && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
 && sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' /opt/google/chrome/google-chrome \
 && google-chrome --version \
 && find /usr/share/doc -type f -exec rm {} \;

# Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Use unicode
RUN locale-gen C.UTF-8 || true

# install jq
RUN JQ_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/jq-latest" \
 && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/jq $JQ_URL \
 && chmod +x /usr/bin/jq \
 && jq --version

# install docker
RUN set -ex \
 && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*-ce\.tgz' | sort -r | head -n 1) \
 && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
 && echo Docker URL: "${DOCKER_URL}" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
 && ls -lha /tmp/docker.tgz \
 && tar -xz -C /tmp -f /tmp/docker.tgz \
 && mv /tmp/docker/* /usr/bin \
 && rm -rf /tmp/docker /tmp/docker.tgz \
 && which docker \
 && (docker version || true)

# docker compose
RUN COMPOSE_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/docker-compose-latest" \
 && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/docker-compose "${COMPOSE_URL}" \
 && chmod +x /usr/bin/docker-compose \
 && docker-compose version

# install dockerize
RUN DOCKERIZE_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/dockerize-latest.tar.gz" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz "${DOCKERIZE_URL}" \
 && tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz \
 && rm -rf /tmp/dockerize-linux-amd64.tar.gz \
 && dockerize --version

# install chromedriver
RUN CHROMEDRIVER_RELEASE=$(curl --silent --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
 && CHROMEDRIVER_URL="http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "${CHROMEDRIVER_URL}" \
 && cd /tmp \
 && unzip chromedriver_linux64.zip \
 && rm -rf chromedriver_linux64.zip \
 && mv chromedriver /usr/local/bin/chromedriver \
 && chmod +x /usr/local/bin/chromedriver \
 && chromedriver --version

RUN NOTOFONT_URL="https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/NotoSansCJKjp-hinted.zip "${NOTOFONT_URL}" \
 && unzip /tmp/NotoSansCJKjp-hinted.zip -d /tmp/NotoSansCJKjp-hinted \
 && mkdir -p /usr/share/fonts/opentype/noto \
 && mv /tmp/NotoSansCJKjp-hinted/*.otf /usr/share/fonts/opentype/noto \
 && chmod 644 /usr/share/fonts/opentype/noto/*.otf \
 && rm -rf /tmp/NotoSansCJKjp-hinted.zip /tmp/NotoSansCJKjp-hinted \
 && fc-cache -f -v

RUN groupadd --gid 3434 circleci \
 && useradd --uid 3434 --gid circleci --shell /bin/bash --create-home circleci \
 && echo 'circleci ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-circleci \
 && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

# start xvfb automatically to avoid needing to express in circle.yml
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
 && chmod +x /tmp/entrypoint \
 && mv /tmp/entrypoint /docker-entrypoint.sh

# ensure that the build agent doesn't override the entrypoint
LABEL com.circleci.preserve-entrypoint=true
ENTRYPOINT ["/docker-entrypoint.sh"]

USER circleci
ENV DISPLAY=:99
ENV LANG=C.UTF-8
ENV PATH=/home/circleci/.yarn/bin:/home/circleci/.rbenv/shims:/home/circleci/.rbenv/bin:/home/circleci/.nodenv/shims:/home/circleci/.nodenv/bin:/home/circleci/.local/bin:$PATH

COPY default.rb /home/circleci/default.rb

RUN cd /home/circleci \
 && git clone --depth 1 https://github.com/rbenv/rbenv.git /home/circleci/.rbenv \
 && git clone --depth 1 https://github.com/rbenv/ruby-build.git /home/circleci/.rbenv/plugins/ruby-build \
 && git clone --depth 1 https://github.com/nodenv/nodenv.git /home/circleci/.nodenv \
 && git clone --depth 1 https://github.com/nodenv/node-build.git /home/circleci/.nodenv/plugins/node-build \
 && git clone --depth 1 https://github.com/nodenv/nodenv-package-rehash.git /home/circleci/.nodenv/plugins/nodenv-package-rehash \
 && echo 'gem: --no-document' >> /home/circleci/.gemrc \
 && MAKE_OPTS=-j2 rbenv install "${RUBY_VERSION}" \
 && rbenv global "${RUBY_VERSION}" \
 && gem update --system \
 && gem update --force \
 && ruby /home/circleci/default.rb | bash -ex \
 && ruby /home/circleci/default.rb | bash -ex \
 && rm $(gem env gemdir)/cache/*.gem /home/circleci/default.rb \
 && rbenv rehash \
 && bundle config clean true \
 && nodenv install "${NODE_VERSION}" \
 && nodenv global "${NODE_VERSION}" \
 && curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version "${YARN_VERSION}" \
 && curl -O https://bootstrap.pypa.io/get-pip.py \
 && python get-pip.py --user \
 && pip install awscli awsebcli --upgrade --user \
 && rm get-pip.py

CMD ["/bin/bash"]
