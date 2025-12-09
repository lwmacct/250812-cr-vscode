# GitHub Container Registry 清理指南

使用 `gh` CLI 清理 ghcr.io 上的无 tag 容器镜像版本。

## 前置条件

- 安装 [GitHub CLI](https://cli.github.com/)
- 已登录 `gh auth login`

- PAT 需要 `read:packages` 和 `delete:packages` 权限

## 常用命令

### 列出所有版本

```bash
# 列出用户的所有 container packages
gh api "/users/{USER}/packages?package_type=container" \
  --jq '.[] | {id, name, repository: .repository.name}'

# 列出指定包的所有版本
gh api "/users/{USER}/packages/container/{PACKAGE}/versions" \
  --jq '.[] | {id, tags: .metadata.container.tags, created_at}'
```

### 删除单个版本

```bash
gh api --method DELETE \
  "/users/{USER}/packages/container/{PACKAGE}/versions/{VERSION_ID}"
```

### 统计无 tag 版本数量

```bash
gh api "/users/{USER}/packages/container/{PACKAGE}/versions" \
  --jq '.[] | select(.metadata.container.tags | length == 0) | .id' | wc -l
```

## 批量清理脚本

GitHub API 默认分页返回 30 条记录，需要循环删除直到清理完成。

### 清理脚本 cleanup-ghcr.sh

```bash
#!/bin/bash
set -e

USER="${1:?用法: $0 <用户名> <包名>}"
PKG="${2:?用法: $0 <用户名> <包名>}"

echo "开始清理 $USER/$PKG 的无 tag 版本..."

while true; do
    ids=$(gh api "/users/$USER/packages/container/$PKG/versions" \
      --jq '.[] | select(.metadata.container.tags | length == 0) | .id')

    if [ -z "$ids" ]; then
        echo "清理完成，无更多 untagged 版本"
        break
    fi

    count=$(echo "$ids" | wc -l)
    echo "发现 $count 个 untagged 版本，开始删除..."

    for id in $ids; do
        gh api --method DELETE \
          "/users/$USER/packages/container/$PKG/versions/$id" --silent
        echo "  已删除: $id"
    done
done

echo ""
echo "剩余版本:"
gh api "/users/$USER/packages/container/$PKG/versions" \
  --jq '.[] | "  \(.id): \(.metadata.container.tags)"'
```

### 使用方法

```bash
chmod +x cleanup-ghcr.sh
./cleanup-ghcr.sh lwmacct 250812-cr-vscode
```

## 组织级别的包

如果包属于组织而非个人用户，将 API 路径中的 `/users/{USER}` 替换为 `/orgs/{ORG}`：

```bash
# 列出组织的包版本
gh api "/orgs/{ORG}/packages/container/{PACKAGE}/versions" \
  --jq '.[] | {id, tags: .metadata.container.tags}'

# 删除组织的包版本
gh api --method DELETE \
  "/orgs/{ORG}/packages/container/{PACKAGE}/versions/{VERSION_ID}"
```

## 注意事项

1. **分页限制**: API 默认返回 30 条，需多轮清理
2. **权限要求**: 普通 `GITHUB_TOKEN` 无法删除包，需要带 `delete:packages` 的 PAT
3. **不可恢复**: 删除操作不可逆，请谨慎操作
4. **速率限制**: 大量删除时注意 API 速率限制

## 相关链接

- [GitHub Docs - Deleting and restoring a package](https://docs.github.com/en/packages/learn-github-packages/deleting-and-restoring-a-package)
- [GitHub REST API - Packages](https://docs.github.com/en/rest/packages)
