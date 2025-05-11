import {
  rule,
  toKey,
  withModifier,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { withinTerminal, withoutTerminal } from "../apps/apps.ts";
import { toJKey, toJKeys, toJKeyWith, UJM } from "../utils/keys.ts";
import { startMode } from "../modes/modes.ts";

const likeCtrlCommands = [
  {
    "8": toJKey("{"),
    "9": toJKey("}"),
  },
];

const likeAltCommands = [{
  h: toJKeyWith("tab", ["control", "shift"]), // 右のタブに移動
  l: toJKeyWith("tab", "control"), // 左のタブに移動
  u: toKey("f7"), // カタカナ変換
  w: toKey("w", "option"), // ウィンドウ切り替え
  "2": toJKeys("#", "#", " "),
  "3": toJKeys("#", "#", "#", " "),
  "4": toJKeys("#", "#", "#", "#", " "),
  "5": toJKeys("#", "#", "#", "#", "#", " "),
}];

export const defaultRule = rule("default").manipulators([
  ...withinTerminal([
    withModifier("control")(likeCtrlCommands),
    withModifier("command")(likeAltCommands),
  ]),
  withoutTerminal([
    withModifier("control")(likeAltCommands),
    withModifier("command")(likeCtrlCommands),
  ]),

  withModifier(["control", "shift"])([
    {
      j: toKey("j", ["control", "command", "shift"]), // ctrl+shift+j はシステムのキーバインドが優先されてしまうため,
      k: toKey("k", ["control", "command", "shift"]), // ctrl+shift+k はシステムのキーバインドが優先されてしまうため,
    },
  ]),

  withModifier("shift")([
    {
      [UJM.PrintScreen]: toKey("1", ["shift", "command"]), // window screenshot
    },
  ]),

  withModifier("option")([
    {
      [UJM.tab]: toKey("f19", "option"), // ミッションコントロール
    },
  ]),

  {
    [UJM.ESC]: toJKeys("ESC", "英数"),
    [UJM.半全]: startMode("NORMAL"),
    [UJM.PrintScreen]: toKey("2", ["command", "shift"]), // range screenshot
    [UJM._]: toKey("international3"),
  },
]);
