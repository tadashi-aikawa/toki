chappy() {
  # chafa --duration 0 --size 40x32 ~/.codex/chappy.gif
  GH_TOKEN=$GH_READONLY_TOKEN AGENT_NAME="codex-cli" codex "$@"
}
