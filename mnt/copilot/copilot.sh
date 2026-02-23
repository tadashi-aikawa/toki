lot() {
  copilot \
    --banner \
    --allow-tool 'write' \
    --allow-tool "shell(git:*)" \
    --deny-tool "shell(git push)" \
    --deny-tool "shell(git reset:*)" \
    --deny-tool "shell(git clean:*)" \
    --allow-tool "shell(gh:*)" \
    --deny-tool "shell(gh api)" \
    --deny-tool "shell(gh pr merge)" \
    --allow-tool "shell(curl)" \
    --allow-url "api.github.com" \
    --allow-url "raw.githubusercontent.com" \
    --allow-url "github.com" \
    "$@"
}
