# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git poetry zsh-navigation-tools zsh-autosuggestions zsh-syntax-highlighting)

# colorscript random

source $ZSH/oh-my-zsh.sh
eval "$(starship init zsh)"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


###########:STARSHIP:###########
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
    zed -a -- "$opened_file"

    rm -f -- "$tmp"
    exit
}


###########:LAZYGIT:###########
function lazygit_zed() {
    lazygit
    exit
}


###########:MY SETTING:###########
bindkey '^H' backward-kill-word
bindkey '5~' kill-word
alias ls='exa'
alias rm='rmt'
alias df='duf'
alias h='btop'
alias hz='history | fzf'
alias c='zed .'
alias e='yazi_cwd'
alias g='lazygit'
alias t='zellij'
alias cl='clear'
alias m='md2html'
alias d='source $(which dotfiles)'
alias p='poetry'
alias pe='poetry shell' # pe -- python environment
alias pa='poetry add'
alias pi='poetry install'
alias pt='poetry show --tree'
alias pp='python -m poetry'
alias py='python'
alias rr='cargo run'
alias alembic='python -m alembic'
alias tttg='make -f /home/blackgolyb/Documents/tic_tac_toe_api/MakefileDocker serveo_restart'
alias gitssh='ssh-add ~/.ssh/github'
alias visossh='ssh-add ~/.ssh/kytas999'
alias viso-setup='git config user.name "kytas999" & git config user.email "kytasevichvlad@gmail.com"'
alias epamssh='ssh-add ~/.ssh/autocode'
alias tfssh='ssh-add ~/.ssh/tf'
alias cht='sh ~/.config/cht/cht.sh'
alias waifu='sh ~/.config/waifu/waifu.sh'

export EDITOR=zed
export VISUAL=zed
export BROWSER=zen-browser

source ~/.phpbrew/bashrc
eval "$(pyenv init -)"

eval "$(zoxide init zsh)"

if [[ -z "${SSH_CONNECTION}" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi


# waifu nsfw
