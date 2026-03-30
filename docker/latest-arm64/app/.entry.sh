#!/usr/bin/env bash
# Admin https://github.com/lwmacct

__main() {

  {
    # 数据隔离, 这一步很关键
    # 如果 /app/data 是挂载路径
    if [[ "$(mount | grep '\s/app/data/?\s' -Ec)" == "1" ]]; then
      mkdir -p /app/data/root/.vscode-server/data
      ln -sfn /app/data/root/.vscode-server/data /root/.vscode-server/data
    fi
  }

  {
    {
      : # 初始化文件
      mkdir -p /app/data/workspace
      tar -vcpf - -C /app/free . | (cd / && tar -xpf - --skip-old-files)
      ln -sfn /app/data/w.code-workspace /root/w.code-workspace
      (cd /app/data && go work init)
    }

    {
      echo "start init"
      for _script in /app/data/init.d/*.sh; do
        if [ -r "$_script" ]; then
          echo "Run $_script"
          timeout 15 bash "$_script"
        fi
      done
    }

    __lwmacct
  } 2>&1 | tee -a /var/log/entry.log

  cat >/etc/supervisord.conf <<EOF
[unix_http_server]
file=/run/supervisord.sock
chmod=0700
chown=nobody:nogroup

[supervisord]
user=root
nodaemon=true
pidfile=/var/run/supervisord.pid
logfile=/var/log/supervisord.log
logfile_maxbytes=100MB
logfile_backups=2

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///run/supervisord.sock
prompt=mysupervisor
history_file=~/.sc_history

[include]
files = /etc/supervisor/conf.d/*.conf /app/data/supervisor.d/*.conf /app/files/app/data/supervisor.d/*.conf
EOF
  exec supervisord

}

__main
