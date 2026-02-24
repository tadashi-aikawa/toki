cx() {
  chafa -s 25 ~/Documents/Pictures/AI/Chappy/chappy-face.webp
  GH_TOKEN=$GH_READONLY_TOKEN codex "$@"
}
