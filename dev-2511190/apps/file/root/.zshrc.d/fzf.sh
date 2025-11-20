#### ----------------- 只在 zsh 环境下启用 -----------------
# 非 zsh 直接返回（如果是被 source 到别的 shell 里时也安全）
if [ -z "${ZSH_VERSION-}" ]; then
  return 0 2>/dev/null || exit 0
fi

#### ----------------- fzf 基础配置（可选） -----------------
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

#### ----------------- 初始化 fd/fdfind -----------------
# 用数组缓存命令和默认参数
typeset -ga FD_CMD

function _fzf_path_init_fd() {
  if command -v fd >/dev/null 2>&1; then
    FD_CMD=(fd --strip-cwd-prefix)
  elif command -v fdfind >/dev/null 2>&1; then
    FD_CMD=(fdfind --strip-cwd-prefix)
  else
    FD_CMD=() # 没有可用 fd 命令
  fi
}

#### ----------------- 判断“当前行是否为空” -----------------
# 把只包含空格/Tab 的情况也当作“空行”
function _fzf_path_is_line_empty() {
  local trimmed="$LBUFFER"
  # 去掉开头的空白字符
  trimmed="${trimmed#"${trimmed%%[![:space:]]*}"}"
  [[ -z "$trimmed" ]]
}

#### ----------------- fzf 选择文件/目录并插入 -----------------
function fzf-path-widget() {
  # 如果没 fd/fdfind，就退回普通字符行为
  if ((${#FD_CMD[@]} == 0)); then
    zle self-insert
    return
  fi

  if _fzf_path_is_line_empty; then
    local target
    # 当前目录下所有文件+目录，遵守 .gitignore，并去掉 ./ 前缀
    # 如需包含隐藏文件，可以改成： "${FD_CMD[@]}" --hidden .
    target=$("${FD_CMD[@]}" . 2>/dev/null | fzf --height 40% --reverse) || return

    BUFFER="$target"
    CURSOR=${#BUFFER}
  else
    # 非“空行前缀”时，当普通字符插入
    zle self-insert
  fi
}

#### ----------------- 绑定按键 -----------------
function _fzf_path_setup() {
  _fzf_path_init_fd

  # 没有 fd/fdfind 就不绑定 widget，避免浪费按键
  ((${#FD_CMD[@]} > 0)) || return

  zle -N fzf-path-widget
  bindkey '/' fzf-path-widget
  bindkey '@' fzf-path-widget
}

_fzf_path_setup
