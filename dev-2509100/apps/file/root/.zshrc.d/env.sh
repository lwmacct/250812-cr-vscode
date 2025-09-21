# shellcheck disable=all
# author https://github.com/lwmacct

__load_taskfile_env() {
  # 禁用 glob 的 no_nomatch 选项, 避免 find 匹配不到文件时依然有输出
  setopt no_nomatch
  {
    # Load .env.template files
    _task_env="$(find /apps/data/workspace/*/.taskfile/ -maxdepth 1 -type f -name '.env.template' 2>/dev/null)"
    while IFS= read -r _env_file; do
      if [[ -f $_env_file ]]; then
        set -a
        source $_env_file
        set +a
      fi
    done <<<"$_task_env"
  }

  {
    # Load .env files
    _task_env="$(find /apps/data/workspace/*/.taskfile/ -maxdepth 1 -type f -name '.env' 2>/dev/null)"
    while IFS= read -r _env_file; do
      if [[ -f $_env_file ]]; then
        set -a
        source $_env_file
        set +a
      fi
    done <<<"$_task_env"
  }

}

__main() {
  # Caution: .env files in git repositories may contain potentially dangerous execution scripts
  __load_taskfile_env

  {
    _env_file="/root/.env"
    set -a
    source $_env_file
    set +a
  }

}
__main
