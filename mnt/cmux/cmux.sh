# ╭──────────────────────────────────────────────────────────╮
# │                     create workspace                     │
# ╰──────────────────────────────────────────────────────────╯
function cnw() {
  ws_id=$(cmux new-workspace | awk '/^OK /{print $2}')
  cmux rename-workspace --workspace "$ws_id" "$1"
  cmux select-workspace --workspace "$ws_id"
}
