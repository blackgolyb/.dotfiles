###########:STARSHIP:###########
eval "$(starship init zsh)"

PROMPT_NEEDS_NEWLINE=false

precmd() {
  if [[ "$PROMPT_NEEDS_NEWLINE" == true ]]; then
    echo
  fi
  PROMPT_NEEDS_NEWLINE=true
}

clear() {
  PROMPT_NEEDS_NEWLINE=false
  command clear
}


###########:YAZI:###########
function yazi_cwd() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    	builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

function yazi_zed() {
    local tmp="$(mktemp -t "yazi-chooser.XXXXX")"
    yazi "$@" --chooser-file="$tmp"

    local opened_file="$(cat -- "$tmp" | head -n 1)"
    zeditor -a -- "$opened_file"

    rm -f -- "$tmp"
    exit
}


###########:LAZYGIT:###########
function lazygit_zed() {
    lazygit
    exit
}


###########:KEYBINDINGS:###########
bindkey '^H' backward-kill-word
bindkey '5~' kill-word
bindkey '^R' fzf-history-widget

###########:ALIASES:###########
alias ls='exa'
alias df='duf'
alias h='btop'
alias hz='history | fzf'
alias c='zeditor .'
alias v='nvim'
alias e='yazi_cwd'
alias g='lazygit'
alias d='lazydocker'
alias t='zellij'
alias ai='aider'
alias nrs='sudo nixos-rebuild switch --flake ~/nixos'
alias nfu='sudo nix flake update --flake ~/nixos'

function activate-ssh-key() {
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/$1 > /dev/null
}

function s() {
    case "$1" in
        git)    activate-ssh-key github ;;
        epam)   activate-ssh-key autocode ;;
        vlad)   activate-ssh-key kytas999 ;;
        rev)    activate-ssh-key revscale ;;
        taras)  activate-ssh-key taras ;;
        tf)     activate-ssh-key tf ;;
        *)      echo "Unknown profile: $1"; echo "Available: git, epam, vlad, rev, taras, tf" ;;
    esac
}

function nd() {
  if [ -z "$1" ]; then
    nix develop --command zsh
  else
    nix develop "/home/$USER/nixos#$1" --command zsh
  fi
}

function my-setup() {
    git config --local user.name "Blackgolyb"
    git config --local user.email "andrejomelnickij@gmail.com"
}

function kytas-setup() {
    git config --local user.name "kytas999"
    git config --local user.email "kytasevichvlad@gmail.com"
}

function tarasw-setup() {
    git config --local user.name "TarasVoievoda"
    git config --local user.email "taras.v.working@gmail.com"
}

function revscale-setup() {
    git config --local user.name "Andrii Omelnitsky"
    git config --local user.email "aomelnitsky@getrevscale.com"
}


###########:ENVIRONMENT:###########
export GOOGLE_CLOUD_PROJECT=ace-bot-441819

export PATH=$HOME/.npm-global/bin:$PATH

eval "$(zoxide init zsh)"

if [[ -z "${SSH_CONNECTION}" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
