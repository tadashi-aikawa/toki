import {
  rule,
  toKey,
  withCondition,
  withModifier,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { App } from "../apps/apps.ts";
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
  // INFO: Raycastと干渉するので注意 (Hammerspoonの設定で回避)
  withCondition(App.is("Finder"))([
    withModifier("command")({
      "2": toJKey("enter"),
    }),
    {
      [UJM.enter]: toJKeyWith("down", "command"),
    },
  ]),
  withCondition(App.is("Ghostty"))([
    withModifier("control")(likeCtrlCommands),
    withModifier("command")(likeAltCommands),
  ]),

  withCondition(App.not("Ghostty"))([
    withModifier("control")(likeAltCommands),
    withModifier("command")(likeCtrlCommands),
  ]),

  withModifier("shift")([
    {
      [UJM.PrintScreen]: toKey("1", ["shift", "command"]), // window screenshot
    },
  ]),

  {
    [UJM.ESC]: toJKeys("ESC", "英数"),
    [UJM.半全]: startMode("NORMAL"),
    [UJM.PrintScreen]: toKey("2", ["command", "shift"]), // range screenshot
    [UJM._]: toKey("international3"),
  },
]);
