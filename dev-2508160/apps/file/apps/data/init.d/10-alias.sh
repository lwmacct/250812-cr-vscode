#!/usr/bin/env bash

{
  : # 设置 host 命令别名
  _file=~/.zshrc.d/alias_host.sh && mkdir -p ${_file%/*}
  if [[ "$(docker ps -f name=host | wc -l)" == "2" ]]; then
    echo "alias host='docker exec -it host nsenter --target 1 --mount --uts --ipc --net --pid bash'" >"$_file"
  else
    echo "alias host='nsenter --mount=/host/proc/1/ns/mnt --net=/host/proc/1/ns/net bash'" >"$_file"
  fi
}
