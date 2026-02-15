# Karabiner Elements 設定生成ソース

[karabiner.ts](https://github.com/evan-liu/karabiner.ts)を使っています。

```bash
deno task dev
```

変更すると[Karabiner Elements](https://karabiner-elements.pqrs.org/)の設定ファイルが勝手に更新されます。

## Hammerspoon連携（モード常時表示）

`toNotificationMessage` の代わりに、`hammerspoon://` URLイベントでモード表示を更新します。

1. `hammerspoon/karabiner_mode_indicator.lua` を `~/.hammerspoon` から読み込む
2. Hammerspoon を起動した状態で Karabiner のモードを切り替える

`~/.hammerspoon/init.lua` の例:

```lua
dofile("/Users/tadashi-aikawa/git/github.com/tadashi-aikawa/toki/karabiner/hammerspoon/karabiner_mode_indicator.lua")
```
