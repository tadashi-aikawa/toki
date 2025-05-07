import {
  layer,
  toKey,
  toPaste,
  withCondition,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { toJKey, toJKeys } from "../utils/keys.ts";
import { App } from "../apps/apps.ts";

export const semicolonLeaderDefinitions = [
  layer(";")
    .leaderMode()
    .manipulators([
      // ObsidianではcommandだとキーがバッティングするのでOptionベースで組み立てるため
      withCondition(App.is("Obsidian"))([
        {
          w: toKey("w", "command"),
        },
      ]),

      {
        "/": toPaste(
          Temporal.Now.plainDateISO().toString().replaceAll("-", "/"),
        ),
        ";": toJKey(";"),
        a: toJKey("^"),
        c: toJKeys("`", "`", "`"),
        d: toJKey("#"),
        e: toJKeys(" ", "=", " "),
        f: toJKey("$"),
        g: toJKey("&"),
        h: toJKey("~"),
        i: toJKeys("{", "}", "<-"),
        k: toJKeys("`", "`", "<-"),
        l: toJKey("_"),
        m: toJKey('"'),
        o: toJKey("|"),
        p: toJKey("%"),
        q: toKey("w", ["control", "shift"]), // ctrl+shift+w
        r: toJKeys(" ", "=", "=", " "),
        s: toJKeys("(", ")", "<-"),
        t: toPaste(Temporal.Now.plainDateISO().toString()),
        u: toJKeys('"', '"', "<-"),
        v: toJKey("'"),
        w: toKey("w", "control"), // ctrl+w
        x: toJKeys("[", "]", "<-"),
        z: toJKey("!"),
      },
    ]),
];
