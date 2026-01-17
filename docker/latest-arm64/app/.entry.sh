#!/usr/bin/env bash
# Admin https://github.com/lwmacct

__lwmacct() {
  # 这部分是作者的私有逻辑, 仅在作者的环境中生效
  _git_user=$(git config --global user.name)
  if [[ "$_git_user" != "lwmacct" ]]; then return; fi
  mkdir -p /app/data/claude && cd /app/data/claude || return

  if [ ! -d "/app/data/claude/commands" ]; then ln -sfn /data/project/260101-claude-code/claude/commands commands; fi
  if [ ! -d "/app/data/claude/rules" ]; then ln -sfn /data/project/260101-claude-code/claude/rules rules; fi
  if [ ! -d "/app/data/claude/skills" ]; then ln -sfn /data/project/260101-claude-code/claude/skills skills; fi
  if [ ! -f "/app/data/claude/CLAUDE.md" ]; then ln -sfn /data/project/260101-claude-code/claude/CLAUDE.md CLAUDE.md; fi

}
# __lwmacct

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
      mkdir -p /app/data/root/.vscode-server/data
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
files = /etc/supervisor/conf.d/*.conf /app/data/supervisor.d/*.conf
EOF
  exec supervisord

}

__main
