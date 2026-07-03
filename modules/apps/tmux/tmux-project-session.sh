set -u

session_prefix='@sessionPrefix@'
dim='\033[2m'
blue='\033[34m'
reset='\033[0m'

git_root() {
  git -C "$1" rev-parse --show-toplevel 2>/dev/null
}

require_tmux_client() {
  if [ -z "${TMUX:-}" ]; then
    printf 'tmux-project-session must run inside an existing tmux client\n' >&2
    exit 1
  fi
}

session_name_for() {
  base=$(basename "$1")
  safe=$(printf '%s' "$base" | tr -cs 'A-Za-z0-9_.-' '-')
  safe=${safe%-}
  hash=$(printf '%s' "$1" | sha1sum | cut -c 1-8)
  printf '%s%s-%s\n' "$session_prefix" "$safe" "$hash"
}

list_project_sessions() {
  tmux list-sessions -F '#S' 2>/dev/null |
    while IFS= read -r session; do
      case "$session" in
        "$session_prefix"*) printf '%s\n' "$session" ;;
      esac
    done
}

list_project_session_choices() {
  current_session=$(tmux display-message -p '#S')

  list_project_sessions |
    while IFS= read -r session; do
      label=${session#"$session_prefix"}
      hash=${label##*-}
      name=${label%"-$hash"}

      current=""
      if [ "$session" = "$current_session" ]; then
        current=" ${blue}(current)${reset}"
      fi

      hash="${dim}${hash}${reset}"

      printf '%s %s%s\t%s\n' \
        "$name" \
        "$hash" \
        "$current" \
        "$session"
    done
}

open_project() {
  require_tmux_client

  if ! root=$(git_root "$1"); then
    printf 'Not inside a Git repository: %s\n' "$1" >&2
    exit 1
  fi

  session=$(session_name_for "$root")

  if tmux has-session -t "$session" 2>/dev/null; then
    tmux switch-client -t "$session"
    exit 0
  fi

  tmux new-session -d -s "$session" -c "$root"
  tmux set-option -t "$session" @project_root "$root" >/dev/null
  tmux switch-client -t "$session"
}

pick_project() {
  require_tmux_client

  choice=$(list_project_session_choices | fzf --ansi --delimiter='\t' --with-nth=1 --prompt='session> ' --layout=reverse --border)
  [ -n "$choice" ] || exit 0
  session=$(printf '%s' "$choice" | cut -f2-)
  tmux switch-client -t "$session"
}

case "${1:---pick}" in
  -l|--list)
    require_tmux_client
    list_project_sessions
    ;;
  -p|--pick)
    pick_project
    ;;
  *)
    open_project "$1"
    ;;
esac
