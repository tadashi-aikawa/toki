# Karabiner Elements 設定生成ソース

[karabiner.ts](https://github.com/evan-liu/karabiner.ts)を使っています。

```bash
deno task dev
```

変更すると[Karabiner Elements](https://karabiner-elements.pqrs.org/)の設定ファイルが勝手に更新されます。

## モード表示

Hammerspoonを使います。`.hammerspoon` 配下に `karabiner_hammerspoon.lua` を実行するパス作成してください。

`~/.hammerspoon/init.lua`
```lua
dofile("<./hammerspoon/karabiner_hammerspoon.lua>のパス")
```

`具体例`
```lua
dofile("/Users/tadashi-aikawa/git/toki/karabiner/hammerspoon/karabiner_hammerspoon.lua")
```

### Hammerspoonファイル構成

- `hammerspoon/karabiner_hammerspoon.lua`: エントリーポイント（モード表示専用）
- `hammerspoon/karabiner/mode_indicator.lua`: モード表示ウィジェット

> **Note:** Window Hints / Focus Border は [jinrai](https://github.com/tadashi-aikawa/jinrai) に分離しました。

### 画像の仕様

画像は `hammerspoon/mode.png` を優先し、存在しない場合は `hammerspoon/hacker-owl.png` を使います。

また、モードごとに画像は着色されます。


| モード名 | 色   |
| -------- | ---- |
| NORMAL   | 青系 |
| RANGE    | 緑系 |
| SPECIAL  | 赤系 |


白線・背景透明の画像がオススメです。
