import {
  modifierLayer,
  toKey,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { App } from "../apps/apps.ts";
import { toJKeyWith, UJM } from "../utils/keys.ts";

export const commandJLeaderDefinitions = [
  modifierLayer("command", "j").condition(App.is("Obsidian")).leaderMode()
    .manipulators([
      {
        // WARN: f13はObsidianだと日本語入力ONになってしまう
        // WARN: f14 ~ f16 は使えない
        f: toKey("f13", "control"), // [AQS] file search
        e: toKey("f13", "command"), // [AQS] recent serarch
        h: toKey("f17"), // [AQS] backlink search
        o: toKey("f18"), // [AQS] floating header search
        l: toKey("f19"), // [AQS] in file serach
        g: toKey("f20"), // [AQS] grep
        s: toJKeyWith(",", "command"), // [AQS] Settings
        [UJM["]"]]: toKey("f20", "shift"), // [AQS] Outgoing links search
      },
    ]),
];
