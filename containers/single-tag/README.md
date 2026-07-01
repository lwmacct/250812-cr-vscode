# single-tag prototype

这个目录是把 `docker/latest-amd64` 和 `docker/latest-arm64` 合并为单个 multi-arch tag 的探索原型，不修改原 `docker/` 目录。

## 结论

可行。现有两个镜像的 `app/` 内容完全一致，差异只在架构相关下载或镜像引用：

- `act`: `x86_64` vs `arm64`
- Go: `linux-amd64` vs `linux-arm64`
- `uv`: `x86_64` vs `aarch64`
- `etcdctl`: 现有 arm64 Dockerfile 使用 `v3.6.11-arm64`，但 `gcr.io/etcd-development/etcd:v3.6.11` 本身已经包含 `linux/amd64` 和 `linux/arm64`

统一 `Dockerfile` 使用 BuildKit 自动注入的 `TARGETARCH` 来映射这些下载名。这个目录现在以 `Dockerfile` 作为唯一事实来源，不再通过模板生成。

构建阶段直接写入 Azure Ubuntu deb822 apt 源，更靠近 hosted runner 网络；镜像末尾会按架构把 apt 源改写为 `mirrors.ustc.edu.cn`，方便交互使用。

## 构建

```bash
containers/single-tag/build.sh ghcr.io/lwmacct/250812-cr-vscode:latest
```

默认构建并推送：

```bash
PLATFORMS=linux/amd64,linux/arm64 containers/single-tag/build.sh
```

构建上下文必须是仓库根目录，因为 Dockerfile 复用现有的 `docker/latest-amd64/app/` 作为公共运行资源。
