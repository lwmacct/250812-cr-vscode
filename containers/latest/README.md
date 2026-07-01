# latest container

这个目录维护 `latest` 镜像的单 Dockerfile multi-arch 构建定义。

## 结论

原 amd64 和 arm64 分体镜像已合并为一个构建定义。两套旧镜像的 `app/` 内容完全一致，公共运行资源现在放在仓库根目录的 `asset/`。

架构差异只保留在下载名或镜像引用映射上：

- `act`: `x86_64` vs `arm64`
- Go: `linux-amd64` vs `linux-arm64`
- `uv`: `x86_64` vs `aarch64`
- `etcdctl`: 现有 arm64 Dockerfile 使用 `v3.6.11-arm64`，但 `gcr.io/etcd-development/etcd:v3.6.11` 本身已经包含 `linux/amd64` 和 `linux/arm64`

统一 `Dockerfile` 使用 BuildKit 自动注入的 `TARGETARCH` 来映射这些下载名。这个目录现在以 `Dockerfile` 作为唯一事实来源，不再通过模板生成。

构建阶段基于 Ubuntu 原始 apt 源备份替换到 Azure Ubuntu 镜像源，更靠近 hosted runner 网络；镜像末尾恢复原始备份后把 apt 源改为 `mirrors.ustc.edu.cn`，方便交互使用。

## 构建

```bash
containers/latest/build.sh ghcr.io/lwmacct/250812-cr-vscode:latest
```

默认构建并推送：

```bash
PLATFORMS=linux/amd64,linux/arm64 containers/latest/build.sh
```

构建上下文必须是仓库根目录，因为 Dockerfile 会复制根目录下的 `asset/` 到镜像 `/app/`。
