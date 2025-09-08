#!/usr/bin/env bash
# shellcheck disable=SC2317
# document https://www.yuque.com/lwmacct/docker/buildx

__main() {
  {
    _sh_path=$(realpath "$(ps -p $$ -o args= 2>/dev/null | awk '{print $2}')") # 当前脚本路径
    _pro_name=$(echo "$_sh_path" | awk -F '/' '{print $(NF-2)}')               # 当前项目名
    _dir_name=$(echo "$_sh_path" | awk -F '/' '{print $(NF-1)}')               # 当前目录名
    _image="${_pro_name}:$_dir_name"
  }

  _dockerfile=$(
    cat <<"EOF"
# https://hub.docker.com/r/arm64v8/ubuntu/
FROM arm64v8/ubuntu:noble-20250805
LABEL maintainer="https://github.com/lwmacct"
ARG DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    echo "配置源, 容器内源文件为 /etc/apt/sources.list.d/ubuntu.sources"; \
    sed -i 's@//ports.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources; \
    apt-get update; apt-get install -y --no-install-recommends ca-certificates curl wget sudo pcp gnupg; \
    sed -i 's@http:@https:@g' /etc/apt/sources.list.d/ubuntu.sources; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    echo "设置 PS1"; \
    cat >> /root/.bashrc <<"MEOF"
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u\[\033[00m\]@\[\033[01;35m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
MEOF

RUN set -eux; \
    echo "语言/时间"; \
    apt-get update; \
    apt-get install -y --no-install-recommends locales fonts-wqy-zenhei fonts-wqy-microhei tzdata; \
    locale-gen zh_CN.UTF-8 en_US.UTF-8; \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    echo "Asia/Shanghai" > /etc/timezone; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    echo;

RUN set -eux; \
    echo "基础软件包"; \
    apt-get update; \
    apt-get dist-upgrade -y; \
    apt-get install -y --no-install-recommends \
        tini supervisor cron vim git jq bc tree zstd zip unzip xz-utils tzdata lsof expect tmux perl sshpass  \
        util-linux bash-completion dosfstools e2fsprogs parted dos2unix kmod pciutils moreutils psmisc \
        openssl openssh-server nftables iptables iproute2 iputils-ping net-tools ethtool socat telnet mtr rsync nfs-common \
        sysstat iftop htop iotop dstat; \
    rm -rf /*-is-merged; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    echo;

RUN set -eux; \
    echo 'install oh-my-zsh'; \
    git clone https://github.com/ohmyzsh/ohmyzsh.git /opt/ohmyzsh; \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /opt/ohmyzsh/custom/plugins/zsh-autosuggestions; \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /opt/ohmyzsh/custom/plugins/zsh-syntax-highlighting; \
    git clone https://github.com/zsh-users/zsh-completions.git /opt/ohmyzsh/custom/plugins/zsh-completions; \
    git clone https://github.com/jimhester/per-directory-history.git /opt/ohmyzsh/custom/plugins/per-directory-history; \
    git clone https://github.com/zsh-users/zsh-history-substring-search.git /opt/ohmyzsh/custom/plugins/zsh-history-substring-search; \
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git /opt/ohmyzsh/custom/plugins/you-should-use; \
    git clone https://github.com/changyuheng/zsh-interactive-cd.git /opt/ohmyzsh/custom/plugins/zsh-interactive-cd; \
    git clone https://github.com/romkatv/powerlevel10k.git /opt/ohmyzsh/custom/themes/powerlevel10k; \
    find /opt/ohmyzsh/ -type d -name '.git'; \
    find /opt/ohmyzsh/ -type d -name '.git' | xargs -r rm -rf;

RUN set -eux; \
    echo 'https://github.com/cli/cli#installation'; \
    (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y; \
    rm -rf  /usr/share/keyrings/githubcli-archive-keyring.gpg /etc/apt/sources.list.d/github-cli.list; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

RUN set -eux; \
    echo "安装 docker-cli https://docs.docker.com/engine/install/ubuntu/"; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; \
    chmod a+r /etc/apt/keyrings/docker.asc; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null; \
    apt-get update && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin docker-buildx-plugin; \
    rm -rf /etc/apt/sources.list.d/docker.list; \
    rm -rf /etc/apt/keyrings/docker.asc; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

RUN set -eux; \
    echo "安装 fluent-bit"; \
    curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

ARG GOPROXY=https://goproxy.cn,direct
ARG GO111MODULE=on
RUN set -eux; \
    echo "安装 Golang https://golang.google.cn/dl/"; \
    _go_version=$(curl -sSL 'go.dev/dl/?mode=json' | jq -r '.[0].version'); \
    echo "获取到 Golang 最新版本: $_go_version"; \
    curl -Lo - "https://golang.google.cn/dl/$_go_version.linux-arm64.tar.gz" | tar zxf - -C /usr/local/; \
    echo "安装常用 Go 工具"; \
    /usr/local/go/bin/go install mvdan.cc/sh/v3/cmd/shfmt@latest; \
    /usr/local/go/bin/go install golang.org/x/tools/cmd/godoc@latest; \
    /usr/local/go/bin/go install golang.org/x/tools/cmd/goimports@latest; \
    /usr/local/go/bin/go install google.golang.org/protobuf/cmd/protoc-gen-go@latest; \
    /usr/local/go/bin/go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest; \
    /usr/local/go/bin/go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest; \
    /usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest; \
    echo "安装 Go 工具完成";
    

RUN set -eux; \
    echo "常用包安装"; \
    apt-get update; apt-get install -y --no-install-recommends \
        bpfcc-tools linux-tools-common \
        build-essential gcc make cmake automake ninja-build shc upx \
        openjdk-17-jdk \
        file strace ltrace valgrind netcat-openbsd \
        git-lfs cron direnv shellcheck fzf zfsutils-linux xxd \
        zsh redis-tools openssh-client supervisor \
        xarclock xvfb x11vnc dbus-x11 \
        dnsutils \
        asciinema \
        umoci skopeo \
        ffmpeg \
        ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

RUN set -eux; \
    echo "python"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dotenv \
        python3-yaml \
        flake8 python3-flake8 python3-autopep8 \
        python3-requests python3-requests-unixsocket \
        python3-openssl python3-bcrypt; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

RUN set -eux; \
    echo "安装 uv"; \
    _uv_version=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | jq -r '.tag_name'); \
    echo "获取到 uv 最新版本: $_uv_version"; \
    wget -qO- "https://github.com/astral-sh/uv/releases/download/$_uv_version/uv-aarch64-unknown-linux-gnu.tar.gz" | tar -xzf - -C /tmp; \
    mv /tmp/uv-aarch64-unknown-linux-gnu/uv /usr/local/bin/uv; \
    mv /tmp/uv-aarch64-unknown-linux-gnu/uvx /usr/local/bin/uvx; \
    chmod +x /usr/local/bin/uv /usr/local/bin/uvx; \
    rm -rf /tmp/uv-aarch64-unknown-linux-gnu; \
    uv venv /opt/venv --system-site-packages; \
    uv pip install --python /opt/venv/bin/python pip; \
    /opt/venv/bin/pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple; \
    uv -V; \
    echo;

RUN set -eux; \
    echo "Installing Node.js and npm"; \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - ; \
    apt-get install -y nodejs; \
    rm -rf /etc/apt/sources.list.d/nodesource.list; \
    npm -v; \
    npm install -g npm@latest; \
    npm -v; \
    echo "Configuring npm to minimize cache"; \
    npm config set cache /tmp/npm-cache; \
    npm config set prefer-offline false; \
    echo "Installing global npm packages"; \
    npm install -g --no-cache \
        vitest \
        degit \
        vue-tsc \
        yarn \
        pnpm \
        pm2 \
        prettier \
        typescript \
        npm-check-updates \
        @go-task/cli \
        @anthropic-ai/claude-code; \
    echo "Cleaning npm cache and temporary files"; \
    npm cache clean --force; \
    rm -rf ~/.npm /tmp/npm-cache; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

# https://github.com/etcd-io/etcd
COPY --from=gcr.io/etcd-development/etcd:v3.6.4-arm64 /usr/local/bin/etcdctl /usr/local/bin/etcdctl

RUN echo "软链接 cron.d" ; \
    rm -rf /etc/cron.d/; \
    ln -sf /apps/data/cron.d/ /etc/cron.d; \
    ln -sf /bin/bash /bin/sh; \
    mkdir -p /root/.ssh; \
    chmod 700 /root/.ssh; \
    echo "StrictHostKeyChecking no" >> /root/.ssh/config;

ENV PATH=/usr/local/go/bin:/opt/venv/bin:/opt/fluent-bit/bin:/root/go/bin:$PATH
ENV TZ=Asia/Shanghai
ENV PYTHONDONTWRITEBYTECODE=1
ENV GOPROXY=https://goproxy.cn,direct
ENV GO111MODULE=on

WORKDIR /apps/data
COPY apps/ /apps/
ENTRYPOINT ["tini", "--"]
CMD ["sh", "-c", "bash /apps/.entry.sh"]

LABEL org.opencontainers.image.source=$_ghcr_source
LABEL org.opencontainers.image.description="专为 VSCode 容器开发环境构建"
LABEL org.opencontainers.image.licenses=MIT
EOF
  )
  {
    cd "$(dirname "$_sh_path")" || exit 1
    echo "$_dockerfile" >Dockerfile

    _ghcr_source=$(sed 's|git@github.com:|https://github.com/|' ../.git/config | grep url | sed 's|.git$||' | awk '{print $NF}')
    sed -i "s|\$_ghcr_source|$_ghcr_source|g" Dockerfile
  }
  {
    if command -v sponge >/dev/null 2>&1; then
      jq 'del(.credsStore)' ~/.docker/config.json | sponge ~/.docker/config.json
    else
      jq 'del(.credsStore)' ~/.docker/config.json >~/.docker/config.json.tmp && mv ~/.docker/config.json.tmp ~/.docker/config.json
    fi
  }
  {
    _registry="ghcr.io/lwmacct" # 托管平台, 如果是 docker.io 则可以只填写用户名
    _repository="$_registry/$_image"
    _buildcache="$_registry/$_pro_name:cache"
    echo "image: $_repository"
    echo "cache: $_buildcache"
    echo "-----------------------------------"
    docker buildx build --builder default --platform linux/arm64 -t "$_repository" --network host --progress plain --load --cache-to "type=registry,ref=$_buildcache,mode=max" --cache-from "type=registry,ref=$_buildcache" . && {
      if false; then
        docker rm -f sss
        docker run -itd --name=sss \
          --restart=always \
          --network=host \
          --privileged=false \
          "$_repository"
        docker exec -it sss bash
      fi
    }
    docker push "$_repository"

  }
}

__main

__help() {
  cat >/dev/null <<"EOF"
这里可以写一些备注

ghcr.io/lwmacct/250209-cr-vscode:dev-2508140

EOF
}
