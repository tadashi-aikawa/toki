claudine() {
  chafa --size 30x24 ~/.claude/claudine-mini.webp
  GH_TOKEN=$GH_READONLY_TOKEN AGENT_NAME="claude-code" claude --permission-mode auto "$@"
}

# cc() {
#   claudine "$@"
# }
