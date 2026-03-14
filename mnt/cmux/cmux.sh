if [[ -n "$CMUX_SHELL_INTEGRATION" ]]; then
  # 知らない間についてたけど必要？？
  # precmd_functions=(${precmd_functions:#_ghostty_precmd})
  # preexec_functions=(${preexec_functions:#_ghostty_preexec})

  # PRの確認は0.1秒以上のラグが出るので強引に無効化する
  _cmux_stop_pr_poll_loop 2>/dev/null || true
  _CMUX_PR_POLL_PID=""
  _CMUX_PR_FORCE=0

  _cmux_start_pr_poll_loop() { return 0 }
  _cmux_stop_pr_poll_loop() { return 0 }
  _cmux_report_pr_for_path() { return 0 }
  _cmux_clear_pr_for_panel() { return 0 }
fi

# ╭──────────────────────────────────────────────────────────╮
# │                     create workspace                     │
# ╰──────────────────────────────────────────────────────────╯
function cnw() {
  ws_id=$(cmux new-workspace | awk '/^OK /{print $2}')
  cmux rename-workspace --workspace "$ws_id" "$1"
  cmux select-workspace --workspace "$ws_id"
}
