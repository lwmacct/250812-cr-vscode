export ZSH="/opt/ohmyzsh"
export ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME="bira" # robbyrussell=默认主题, agnoster=高亮主题, bira = 简单主题
plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  per-directory-history
  zsh-history-substring-search
  you-should-use
  zsh-interactive-cd
  git
  docker
)

source $ZSH/oh-my-zsh.sh

{
  : # 执行 ~/.zshrc.d/*.sh
  _file=~/.zshrc.d/alias.sh && mkdir -p ${_file%/*}
  touch $_file
  for file in ~/.zshrc.d/*.sh; do
    if [[ -r $file ]]; then
      source "$file"
    fi
  done
}
