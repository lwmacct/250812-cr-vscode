#!/usr/bin/env bash

# 检查一次 关闭 vscode-server 已运一小时, 而且没有客户端客连接的 vscode-server 进程
__kill_vscode_server() {
  # shellcheck disable=SC2009
  if [[ $(ps -ef | grep -v $$ | grep 'type=fileWatcher$' -c) == '0' ]]; then
    _last_pid=$(ps -ef | grep '(vscode|cursor)-server.*node\s' -E | awk '{print $2}' | sort -n | tac | head -n1)
    _etimes=$(ps -p "$_last_pid" -o etimes= | tr -d ' ' | head -n1)
    echo "_last_pid: $_last_pid, _etimes: $_etimes"
    if [[ -n "$_etimes" ]] && [[ "$_etimes" =~ ^[0-9]+$ ]] && ((_etimes > 3600)); then
      pkill -f '# Watch|vscode-server|cursor-server'
    fi

  fi
}
__kill_vscode_server
