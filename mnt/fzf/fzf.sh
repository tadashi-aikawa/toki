export FZF_DEFAULT_OPTS="
  --reverse
  --style=full:rounded
  --height 45%
  --margin 0,5%
"

iz() {
  local selected
  selected=$(fzf) || return
  cd -- "${selected:h}" || exit
}
