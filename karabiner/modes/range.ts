import {
  layer,
  toKey,
  withCondition,
  withModifier,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { toJKey, toJKeyWith, UJM, UNUSED_KEY } from "../utils/keys.ts";
import { App } from "../apps/apps.ts";
import { changeMode, terminateMode } from "./modes.ts";

const likeCtrlCommands = [
  {
    h: toJKeyWith("<-", "shift", 5),
    j: toJKeyWith("down", "shift", 5),
    k: toJKeyWith("up", "shift", 5),
    l: toJKeyWith("->", "shift", 5),
  },
];

export const rangeModeDefinitions = layer(UNUSED_KEY, "RANGE")
  .leaderMode({
    sticky: true,
  })
  .manipulators([
    withCondition(App.is("Ghostty"))([
      withModifier("control")(likeCtrlCommands),
    ]),
    withCondition(App.not("Ghostty"))([
      withModifier("command")(likeCtrlCommands),
    ]),

    withModifier("shift")({
      h: toJKeyWith("<-", "shift", 25),
      j: toJKeyWith("down", "shift", 25),
      k: toJKeyWith("up", "shift", 25),
      l: toJKeyWith("->", "shift", 25),

      f: toJKeyWith("down", ["command", "shift"]),
    }),

    {
      ";": toJKeyWith("->", ["control", "shift"]),
      [UJM.ESC]: [...terminateMode("RANGE"), toKey("japanese_eisuu")],
      [UJM.半全]: [...terminateMode("RANGE"), toKey("japanese_eisuu")],
      a: toJKeyWith("<-", ["control", "shift"]),
      b: toJKeyWith("<-", ["option", "shift"]),
      c: [...changeMode("RANGE", "NORMAL"), toKey("c", "command")],
      d: [...changeMode("RANGE", "NORMAL"), toJKey("bs")],
      f: toJKeyWith("up", ["command", "shift"]),
      g: changeMode("RANGE", "NORMAL"),
      h: toJKeyWith("<-", "shift"),
      j: toJKeyWith("down", "shift"),
      k: toJKeyWith("up", "shift"),
      l: toJKeyWith("->", "shift"),
      o: [...changeMode("RANGE", "NORMAL"), toJKey("del")],
      u: [...changeMode("RANGE", "NORMAL"), toJKey("bs")],
      w: toJKeyWith("->", ["option", "shift"]),
      x: [...changeMode("RANGE", "NORMAL"), toKey("x", "command")],
    },
  ]);
