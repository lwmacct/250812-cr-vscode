# shellcheck disable=all
# author https://github.com/lwmacct

# 安全加载 env 文件：只解析 KEY=VALUE 格式，拒绝可执行内容
_safe_source_env() {
  local file=$1
  [[ ! -f $file ]] && return 0

  local key value
  while IFS='=' read -r key value || [[ -n $key ]]; do
    # 跳过空行和注释
    [[ -z $key || $key == \#* ]] && continue

    # 验证 key 格式：必须是合法的变量名
    [[ ! $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && continue

    # 安全检测：拒绝包含危险字符的 value
    case $value in
      *'$'* | *'`'* | *'\\'*)
        echo "[env.sh] 跳过危险行 ($file): $key=..." >&2
        continue
        ;;
    esac

    export "$key=$value"
  done < "$file"
}

__main() {
  [[ -n $ZSH_VERSION ]] && setopt no_nomatch

  # 按优先级加载 env 文件（后加载的覆盖先加载的）
  _safe_source_env /app/data/workspace/.env.example
  _safe_source_env /app/data/workspace/.env
  _safe_source_env /root/.env
}

__main
