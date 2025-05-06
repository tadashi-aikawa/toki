import {
  layer,
  toKey,
  toPaste,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { toJKey, toJKeys } from "../utils/keys.ts";

export const semicolonLeaderDefinitions = [
  layer(";")
    .leaderMode()
    .manipulators({
      "/": toPaste(Temporal.Now.plainDateISO().toString().replaceAll("-", "/")),
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
      r: toJKeys(" ", "=", "=", " "),
      s: toJKeys("(", ")", "<-"),
      t: toPaste(Temporal.Now.plainDateISO().toString()),
      u: toJKeys('"', '"', "<-"),
      v: toJKey("'"),
      w: toKey("w", "control"), // ctrl+w
      x: toJKeys("[", "]", "<-"),
      z: toJKey("!"),
    }),
];
