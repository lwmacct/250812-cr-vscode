#!/usr/bin/env bash
# Admin https://github.com/lwmacct

__update_260114() {
  # 更新旧的项目结构, 仓库直接放置到 workspace 目录下, 之前的结构是 workspace/项目名
  _name="$(hostname)"
  if [[ "$(echo "$_name" | grep '^[0-9]{6}-' -Ec)" != "1" ]]; then return; fi

  _project_dir="/app/data/workspace/$_name"
  _backups_dir="/app/data/workspace-260106"

  # 如果项目目录存在, 则进行迁移到新的结构
  if [ -d "$_project_dir" ]; then
    mv /app/data/workspace $_backups_dir        # 备份工作区
    mv $_backups_dir/$_name /app/data/workspace # 恢复工作区
  fi
}
__update_260114

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
    # 数据隔离, 这一步很关键
    mkdir -p /app/data/root/.vscode-server/data
    ln -sfn /app/data/root/.vscode-server/data /root/.vscode-server/data
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
