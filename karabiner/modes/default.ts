import {
  rule,
  toKey,
  withModifier,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { withinTerminal, withoutTerminal } from "../apps/apps.ts";
import { toJKey, toJKeys, toJKeyWith, UJM } from "../utils/keys.ts";
import { startMode } from "../modes/modes.ts";
import { toDynamicPaste } from "../utils/commands.ts";

const likeCtrlCommands = [
  {
    "2": toKey("f2"),
    "8": toJKey("{"),
    "9": toJKey("}"),
    // ウィンドウを隠すに割り当てられているのを無効化するためきりかえ
    "h": toKey("h", "Hyper"),
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

const likeCtrlShiftCommands = [{
  j: toKey("f15", ["control", "command"]), // ctrl+shift+j はシステムのキーバインドが優先されてしまうため,
  k: toKey("f16", ["control", "command"]), // ctrl+shift+k はシステムのキーバインドが優先されてしまうため,
  ";": toDynamicPaste('date "+%Y%m%d"'),
}];

export const defaultRule = rule("default").manipulators([
  ...withinTerminal([
    withModifier("control")(likeCtrlCommands),
    withModifier("command")(likeAltCommands),
    withModifier(["control", "shift"])(likeCtrlShiftCommands),
  ]),
  withoutTerminal([
    withModifier("control")(likeAltCommands),
    withModifier("command")(likeCtrlCommands),
    withModifier(["command", "shift"])(likeCtrlShiftCommands),
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
