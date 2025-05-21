#!/usr/bin/env sh

function update_config() {
    PROJECT_DIR=$(get_dotfiles_dir)
    SCRIPTS_DOTFILES_DIR=${PROJECT_DIR}/scripts
    sh $SCRIPTS_DOTFILES_DIR/install_config.sh
}

function go_to_dotfiles() {
    dotdir=$(get_dotfiles_dir)
    cd $dotdir
}

function open_dotfiles() {
    go_to_dotfiles
    if [[ -n "${EDITOR}" ]]; then
        $($EDITOR .)
    fi
}

function sync_dotfiles() {
    go_to_dotfiles && \
    git pull --rebase && \
    git push && \
    update_config
}

case $1 in
    "sync")
        sync_dotfiles
        ;;
    "update_config")
        update_config
        ;;
    "go")
        go_to_dotfiles
        ;;
    "open")
        open_dotfiles
        ;;
    "")
        open_dotfiles
        ;;
    *)
        echo "No option $1"
esac
