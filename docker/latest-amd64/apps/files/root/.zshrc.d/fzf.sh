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
typeset -ga _FD_CMD

__fzf_path_init_fd() {
  if command -v fd >/dev/null 2>&1; then
    _FD_CMD=(fd --strip-cwd-prefix)
  elif command -v fdfind >/dev/null 2>&1; then
    _FD_CMD=(fdfind --strip-cwd-prefix)
  else
    _FD_CMD=() # 没有可用 fd 命令
  fi
}

#### ----------------- 判断"当前行是否为空" -----------------
# 把只包含空格/Tab 的情况也当作"空行"
__fzf_path_is_line_empty() {
  local _trimmed="$LBUFFER"
  # 去掉开头的空白字符
  _trimmed="${_trimmed#"${_trimmed%%[![:space:]]*}"}"
  [[ -z "$_trimmed" ]]
}

#### ----------------- fzf 历史搜索 widget -----------------
__fzf_history_widget() {
  local _selected=$(fc -rl 1 | fzf --height 40% --reverse --prompt='' +s --tac)
  if [[ -n "$_selected" ]]; then
    # 移除历史行号前缀 (如 "  123 command")
    local _cmd="${_selected#*[[:space:]][[:space:]]}"
    BUFFER="$_cmd"
    CURSOR=${#BUFFER}
  fi
  zle reset-prompt
}
zle -N __fzf_history_widget

#### ----------------- fzf 选择文件/目录并插入 -----------------
__fzf_path_widget() {
  # 如果没 fd/fdfind，就退回普通字符行为
  if ((${#_FD_CMD[@]} == 0)); then
    zle self-insert
    return
  fi

  if __fzf_path_is_line_empty; then
    local _target
    # 当前目录下所有文件+目录，遵守 .gitignore，并去掉 ./ 前缀
    # 如需包含隐藏文件，可以改成： "${_FD_CMD[@]}" --hidden .
    _target=$("${_FD_CMD[@]}" . 2>/dev/null | fzf --height 40% --reverse --prompt '')
    local _ret=$?
    if [[ $_ret -ne 0 ]]; then
      zle reset-prompt
      return $_ret
    fi

    BUFFER="$_target"
    CURSOR=${#BUFFER}
    zle reset-prompt # 重绘命令行
  else
    # 非"空行前缀"时，当普通字符插入
    zle self-insert
  fi
}

#### ----------------- 主入口 -----------------
__main() {
  __fzf_path_init_fd

  # 没有 fd/fdfind 就不绑定 widget，避免浪费按键
  ((${#_FD_CMD[@]} > 0)) || return

  zle -N __fzf_path_widget
  bindkey '/' __fzf_history_widget # / → 历史搜索
  bindkey '@' __fzf_path_widget    # @ → 路径搜索
}

__main
