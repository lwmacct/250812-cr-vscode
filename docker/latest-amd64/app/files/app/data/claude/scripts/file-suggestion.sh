#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# file-suggestion.sh - Claude Code 文件建议增强脚本
#
# 解决问题:
#   1. Claude Code 默认的文件建议不显示软链接(symlink)文件
#   2. .claude 目录在 .gitignore 中但仍需被搜索到
#
# 解决方案:
#   1. 使用 fd --follow 跟随符号链接进行搜索
#   2. 尊重 .gitignore，但对 .claude 目录单独搜索后合并结果
#
# 依赖: fd-find (fd/fdfind), jq
#
# 用法: 配置为 Claude Code 的 file suggestion hook
# 输入: stdin JSON {"query": "搜索关键词"}
# 输出: stdout 匹配的文件路径列表（每行一个路径）
# ------------------------------------------------------------------------------
set -euo pipefail

# Read {"query": "..."} from stdin
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq not found. Please install jq." >&2
  exit 1
fi
query="$(cat | jq -r '.query // ""')"

project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$project"

# Pick fd command name (Debian/Ubuntu uses fdfind)
if command -v fd >/dev/null 2>&1; then
  FDCMD="fd"
elif command -v fdfind >/dev/null 2>&1; then
  FDCMD="fdfind"
else
  echo "Error: fd/fdfind not found. Please install fd-find." >&2
  exit 1
fi

# Emit newline-delimited candidate paths (no leading "./"), max ~99 items
{
  # 1. 正常搜索，尊重 .gitignore
  "$FDCMD" \
    --follow \
    --hidden \
    --color=never \
    --full-path \
    --exclude .git \
    --exclude node_modules \
    --exclude dist \
    --exclude build \
    "$query" .

  # 2. 单独搜索 .claude 目录（使用 --no-ignore 绕过 .gitignore）
  if [[ -d ".claude" ]]; then
    "$FDCMD" \
      --follow \
      --hidden \
      --color=never \
      --full-path \
      --no-ignore \
      "$query" .claude
  fi
} |
  sed 's|^\./||' |
  sort -u
