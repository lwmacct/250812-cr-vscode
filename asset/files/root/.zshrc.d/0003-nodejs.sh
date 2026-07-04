# shellcheck disable=all
# author https://github.com/lwmacct
# 判断是否存在 /app/data/root/.nvm

# fnm
FNM_PATH="/root/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --use-on-cd --shell zsh)"
  exit 0
fi

# nvm
if [ -d "/app/data/root/.nvm" ]; then
  export NVM_DIR="/app/data/root/.nvm"
fi
if [ -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
