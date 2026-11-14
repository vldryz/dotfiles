# +-----------------+
# | GENERAL         |
# +-----------------+

alias ll="ls -lahF"
alias la="ls -A"
(( $+commands[zoxide] )) && alias cd="z"  # without zoxide, keep the builtin cd
alias svenv="source .venv/bin/activate"
alias brup="brew update && brew upgrade"
alias upall="$HOME/dotfiles/scripts/upgrade-all.sh"
alias brlist="$HOME/dotfiles/scripts/list-brew-installs.sh"

# +-----------------+
# | GIT             |
# +-----------------+

alias gs="git status"
alias gc="git commit -m"
alias ga="git add"
alias gp="git push"
alias gco="git checkout"
alias gbr="git branch"
alias glog="git log --oneline --decorate --graph"
