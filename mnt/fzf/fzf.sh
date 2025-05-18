export FZF_DEFAULT_OPTS="--reverse --border --height 50%"
# FindItFasterを実行するために開かれたターミナル起動時は異なる設定にする
if [[ $FIND_IT_FASTER_ACTIVE -eq 1 ]]; then
  FZF_DEFAULT_OPTS="--reverse --border --height 90%"
fi
