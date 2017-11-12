# https://2699-85091879-gh.circle-artifacts.com/0/circleci-bundles/ruby/images/2.4.2-stretch/Dockerfile
# https://2699-85091879-gh.circle-artifacts.com/0/circleci-bundles/ruby/images/2.4.2-stretch/node/Dockerfile
# https://2699-85091879-gh.circle-artifacts.com/0/circleci-bundles/ruby/images/2.4.2-stretch/node-browsers/Dockerfile
# https://github.com/noonat/docker-rbenv-nodenv/blob/master/Dockerfile
FROM ubuntu:xenial

ARG APT_MIRROR=JP
ARG RUBY_VERSION=2.4.2
ARG NODE_VERSION=8.9.1

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i'~' -e "s%http://archive.ubuntu.com/ubuntu%mirror://mirrors.ubuntu.com/${APT_MIRROR}.txt%g" /etc/apt/sources.list \
 && echo 'Acquire::Queue-Mode "host";' > /etc/apt/apt.conf.d/75download \
 && echo 'Acquire::http::Pipeline-Depth "10";' >> /etc/apt/apt.conf.d/75download \
 && apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    autoconf \
    bison \
    build-essential \
    bzip2 \
    ca-certificates \
    curl \
    git \
    git-core \
    gzip \
    libcurl4-openssl-dev \
    libffi-dev \
    libgdbm-dev \
    libgdbm3 \
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
    xvfb \
    zip \
    zlib1g-dev \
 && CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb $CHROME_URL \
 && (dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -fy install)  \
 && sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' /opt/google/chrome/google-chrome \
 && google-chrome --version \
 && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
 && find /usr/share/doc -type f -exec rm {} \;

# Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Use unicode
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

# install jq
RUN JQ_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/jq-latest" \
  && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/jq $JQ_URL \
  && chmod +x /usr/bin/jq \
  && jq --version

# install docker
RUN DOCKER_VERSION=$(curl --silent --location --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*-ce\.tgz' | sort -r | head -n 1) \
 && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
 && echo Docker URL: $DOCKER_URL \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
 && ls -lha /tmp/docker.tgz \
 && tar -xz -C /tmp -f /tmp/docker.tgz \
 && mv /tmp/docker/* /usr/bin \
 && rm -rf /tmp/docker /tmp/docker.tgz \
 && which docker \
 && (docker version || true)

# install dockerize
RUN DOCKERIZE_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/dockerize-latest.tar.gz" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz $DOCKERIZE_URL \
 && tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz \
 && rm -rf /tmp/dockerize-linux-amd64.tar.gz \
 && dockerize --version

# install chromedriver
RUN CHROMEDRIVER_RELEASE=$(curl --silent --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
 && CHROMEDRIVER_URL="http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip $CHROMEDRIVER_URL \
 && cd /tmp \
 && unzip chromedriver_linux64.zip \
 && rm -rf chromedriver_linux64.zip \
 && mv chromedriver /usr/local/bin/chromedriver \
 && chmod +x /usr/local/bin/chromedriver \
 && chromedriver --version

# start xvfb automatically to avoid needing to express in circle.yml
ENV DISPLAY :99
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
 && chmod +x /tmp/entrypoint \
 && mv /tmp/entrypoint /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

RUN NOTOFONT_URL="https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip" \
 && curl --silent --show-error --location --fail --retry 3 --output /tmp/NotoSansCJKjp-hinted.zip $NOTOFONT_URL \
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

USER circleci

# Clone everything, and setup the path.
RUN git clone --depth 1 https://github.com/rbenv/rbenv.git /home/circleci/.rbenv \
 && git clone --depth 1 https://github.com/rbenv/ruby-build.git /home/circleci/.rbenv/plugins/ruby-build \
 && git clone --depth 1 https://github.com/nodenv/nodenv.git /home/circleci/.nodenv \
 && git clone --depth 1 https://github.com/nodenv/node-build.git /home/circleci/.nodenv/plugins/node-build \
 && git clone --depth 1 https://github.com/nodenv/nodenv-package-rehash.git /home/circleci/.nodenv/plugins/nodenv-package-rehash \
 && echo 'gem: --no-ri --no-rdoc' >> /home/circleci/.gemrc
ENV PATH /home/circleci/.yarn/bin:/home/circleci/.rbenv/shims:/home/circleci/.rbenv/bin:/home/circleci/.nodenv/shims:/home/circleci/.nodenv/bin:/home/circleci/.local/bin:$PATH

# ensure that the build agent doesn't override the entrypoint
LABEL com.circleci.preserve-entrypoint=true

WORKDIR /home/circleci

RUN rbenv install "${RUBY_VERSION}" \
 && rbenv global "${RUBY_VERSION}"

RUN nodenv install "${NODE_VERSION}" \
 && nodenv global "${NODE_VERSION}"

RUN gem update --system \
 && gem update --force \
 && curl -o- -L https://yarnpkg.com/install.sh | bash -s --

RUN curl -O https://bootstrap.pypa.io/get-pip.py \
 && python get-pip.py --user \
 && pip install awscli awsebcli --upgrade --user \
 && pip --version && aws --version && eb --version \
 && rm get-pip.py

CMD ["/bin/sh"]
