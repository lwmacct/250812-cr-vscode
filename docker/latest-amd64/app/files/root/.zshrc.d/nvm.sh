# shellcheck disable=all
# author https://github.com/lwmacct
# 判断是否存在 /app/data/root/.nvm

if [ -d "/app/data/root/.nvm" ]; then
  export NVM_DIR="/app/data/root/.nvm"
fi
if [ -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
