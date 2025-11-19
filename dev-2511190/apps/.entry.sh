#!/usr/bin/env bash
# Admin https://www.yuque.com/lwmacct

__main() {
  {
    # 历史遗留处理
    rm -rf /apps/data/init.d/99-supervisord.sh
  }

  {
    : # 初始化文件
    mkdir -p /apps/data/{workspace,logs,script,cron.d,supervisor.d}
    tar -vcpf - -C /apps/file . | (cd / && tar -xpf - --skip-old-files)
    (cd /apps/data/workspace && go work init)
  } 2>&1 | tee /apps/data/logs/entry-tar.log

  {
    echo "start init"
    for _script in /apps/data/init.d/*.sh; do
      if [ -r "$_script" ]; then
        echo "Run $_script"
        timeout 30 bash "$_script"
      fi
    done
  } 2>&1 | tee -a /apps/data/logs/entry-init.log

  cat >/etc/supervisord.conf <<EOF
[unix_http_server]
file=/run/supervisord.sock
chmod=0700
chown=nobody:nogroup

[supervisord]
user=root
nodaemon=true
logfile=/var/log/supervisord.log
logfile_maxbytes=5MB
logfile_backups=2
pidfile=/var/run/supervisord.pid

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///run/supervisord.sock
prompt=mysupervisor
history_file=~/.sc_history

[include]
files = /etc/supervisor/conf.d/*.conf /apps/data/supervisor.d/*.conf
EOF
  exec supervisord

}

__main
