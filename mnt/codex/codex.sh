chappy() {
  chafa --size 30x24 ~/.codex/chappy-mini.webp
  GH_TOKEN=$GH_READONLY_TOKEN AGENT_NAME="codex-cli" codex "$@"
}
