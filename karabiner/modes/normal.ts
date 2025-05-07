import {
  layer,
  toKey,
  withCondition,
  withModifier,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { toJKey, toJKeys, toJKeyWith, UJM, UNUSED_KEY } from "../utils/keys.ts";
import { App } from "../apps/apps.ts";
import { changeMode, terminateMode } from "./modes.ts";

const likeCtrlCommands = [
  {
    h: toJKeys("<-", 5),
    j: toJKeys("down", 5),
    k: toJKeys("up", 5),
    l: toJKeys("->", 5),

    e: toJKeyWith("->", "command"),
  },
];

export const normalModeDefinitions = layer(UNUSED_KEY, "NORMAL")
  .leaderMode({
    sticky: true,
  })
  .manipulators([
    withCondition(App.is("Obsidian"))([
      {
        q: toKey("w", ["option", "shift"]),
      },
    ]),
    withCondition(App.is("Finder"))([
      withModifier("command")({
        e: toJKeyWith("]", "command"),
      }),
      {
        o: toJKeyWith("bs", "command"),
        e: toJKeyWith("[", "command"),
      },
    ]),
    withCondition(App.is("Ghostty"))([
      withModifier("control")(likeCtrlCommands),
      withModifier("shift")({
        f: toJKeyWith("end", "control"),
      }),
      {
        ";": toJKeyWith("->", "command"),
        a: toJKeyWith("<-", "command"),
        f: toJKeyWith("home", "control"),
      },
    ]),

    withCondition(App.not("Ghostty"))([
      withModifier("command")(likeCtrlCommands),
    ]),

    withModifier("shift")({
      h: toJKeys("<-", 10),
      j: toJKeys("down", 25),
      k: toJKeys("up", 25),
      l: toJKeys("->", 10),

      f: toJKeyWith("down", "command"),
      o: toJKeys("del", 5),
      u: toJKeys("bs", 5),
    }),

    {
      ",": [...terminateMode("NORMAL"), toKey("japanese_eisuu")],
      ".": [toJKey("="), ...terminateMode("NORMAL")],
      ";": toKey("e", "control"),
      [UJM.ESC]: [...terminateMode("NORMAL"), toKey("japanese_eisuu")],
      [UJM.半全]: [...terminateMode("NORMAL"), toKey("japanese_eisuu")],
      [UJM[":"]]: [...terminateMode("NORMAL"), toKey("japanese_kana")],
      a: toKey("a", "control"),
      b: toJKeyWith("<-", "option"),
      c: toKey("c", "command"),
      d: toJKey("bs"),
      e: toJKeyWith("<-", "command"),
      f: toJKeyWith("up", "command"),
      g: changeMode("NORMAL", "RANGE"),
      h: toJKey("<-"),
      j: toJKey("down"),
      k: toJKey("up"),
      l: toJKey("->"),
      m: [toKey("japanese_eisuu"), ...terminateMode("NORMAL")],
      o: toJKey("del"),
      q: toKey("w", "command"),
      r: changeMode("NORMAL", "SPECIAL"),
      t: toJKeyWith("->", ["control", "option", "command"]),
      u: toJKey("bs"),
      v: toKey("v", "command"),
      w: toJKeyWith("->", "option"),
      y: toKey("y", "command"),
      z: toKey("z", "command"),
      4: toKey("m", "command"),
    },
  ]);
