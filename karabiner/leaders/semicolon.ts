import { layer, toKey, withCondition } from "karabiner.ts";
import { toJKey, toJKeys, UJM } from "../utils/keys.ts";
import { App } from "../apps/apps.ts";
import { toDynamicPaste } from "../utils/commands.ts";

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
        "/": toDynamicPaste('date "+%Y/%m/%d"'),
        [UJM[":"]]: toDynamicPaste('date "+%H:%M"'),
        [UJM["enter"]]: toKey("f18", ["option"]), // Homerow起動用
        [UJM["ESC"]]: toKey("f17", ["option"]), // Homerow search起動用
        [UJM[" "]]: [toKey("f20", ["option"]), toKey("f20", ["option"])], // Scoot起動用. 2回押しなのは1度押しだとScootが安定しないから
        ";": toJKey(";"),
        a: toJKey("^"),
        c: toJKeys("`", "`", "`"),
        d: toJKey("#"),
        e: toJKeys(" ", "=", " "),
        f: toJKey("$"),
        g: toJKey("&"),
        h: toJKey("~"),
        i: toJKeys("{", "}", "<-"),
        j: toJKeys("'", "'", "<-"),
        k: toJKeys("`", "`", "<-"),
        l: toJKey("_"),
        m: toJKey('"'),
        o: toJKey("|"),
        p: toJKey("%"),
        q: toKey("w", ["control", "shift"]), // ctrl+shift+w
        r: toJKeys(" ", "=", "=", " "),
        s: toJKeys("(", ")", "<-"),
        t: toDynamicPaste('date "+%Y-%m-%d"'),
        u: toJKeys('"', '"', "<-"),
        v: toJKey("'"),
        w: toKey("w", "control"), // ctrl+w
        x: toJKeys("[", "]", "<-"),
        z: toJKey("!"),
      },
    ]),
];
