#!/usr/bin/env bash
# Admin https://www.yuque.com/lwmacct

__main() {

  {
    # 清理旧的符号链接
    _is=$(ls -al /root | grep "/apps/files/root/.profile$" | wc -l)
    echo "_is=$_is"

    if [[ "$_is" != "0" ]]; then
      echo "clean old symlinks"
      find "/root" -maxdepth 1 -xtype l -delete
      find "/app/data" -maxdepth 1 -xtype l -delete
      sed -i 's|/apps/data|/app/data|g' /app/data/w.code-workspace
      sync && sleep 1 && exit 0
    fi
  }

  {
    {
      : # 初始化文件
      mkdir -p /app/data/workspace
      tar -vcpf - -C /app/free . | (cd / && tar -xpf - --skip-old-files)
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
files = /etc/supervisor/conf.d/*.conf /app/data/supervisor.d/*.conf
EOF
  exec supervisord

}

__main
