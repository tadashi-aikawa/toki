cx() {
  chafa --duration 0 --size 40x32 ~/.codex/chappy.gif
  GH_TOKEN=$GH_READONLY_TOKEN codex "$@"
}
