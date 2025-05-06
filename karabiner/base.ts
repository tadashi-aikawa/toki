import {
  rule,
  toKey,
  withCondition,
  withModifier,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { App } from "./apps/apps.ts";
import { toJKey, toJKeys, toJKeyWith, UJM } from "./utils/keys.ts";
import { startMode } from "./modes/modes.ts";

const likeCtrlCommands = [
  {
    "8": toJKey("{"),
    "9": toJKey("}"),
  },
];

const likeAltCommands = [{
  h: toJKeyWith("tab", ["control", "shift"]),
  l: toJKeyWith("tab", "control"),
  u: toKey("f7"),
  "2": toJKeys("#", "#", " "),
  "3": toJKeys("#", "#", "#", " "),
  "4": toJKeys("#", "#", "#", "#", " "),
  "5": toJKeys("#", "#", "#", "#", "#", " "),
}];

export const defaultRule = rule("default").manipulators([
  withCondition(App.is("Ghostty"))([
    withModifier("control")(likeCtrlCommands),
    withModifier("command")(likeAltCommands),
  ]),

  withModifier("control")(likeAltCommands),
  withModifier("command")(likeCtrlCommands),

  {
    [UJM.ESC]: toJKeys("ESC", "英数"),
    [UJM.半全]: startMode("NORMAL"),
  },
]);
