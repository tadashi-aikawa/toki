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
    --allow-tool "shell(pnpm pre:push:*)" \
    --allow-tool "shell(curl)" \
    --allow-url "api.github.com" \
    --allow-url "raw.githubusercontent.com" \
    --allow-url "github.com" \
    --allow-url "minerva.mamansoft.net" \
    "$@"
}

export COPILOT_NOTIFY_ALLOW_TOOL_RULES="write,shell(git:*),shell(gh:*),shell(pnpm pre:push:*),shell(curl)"
export COPILOT_NOTIFY_DENY_TOOL_RULES="shell(git push),shell(git reset:*),shell(git clean:*),shell(gh api),shell(gh pr merge)"
export COPILOT_NOTIFY_ALLOW_URLS="api.github.com,raw.githubusercontent.com,github.com,minerva.mamansoft.net"
