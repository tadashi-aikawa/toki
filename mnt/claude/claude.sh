claudine() {
  chafa --duration 0 --size 30x24 ~/.claude/claudine.gif
  GH_TOKEN=$GH_READONLY_TOKEN claude "$@"
}
