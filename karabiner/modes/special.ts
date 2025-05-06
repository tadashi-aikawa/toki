import { layer, toKey } from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { UJM, UNUSED_KEY } from "../utils/keys.ts";
import { terminateMode } from "./modes.ts";

export const specialModeDefinitions = layer(UNUSED_KEY, "SPECIAL")
  .leaderMode({ sticky: true })
  .manipulators([
    {
      ",": toKey("keypad_2"),
      ".": toKey("keypad_3"),
      [UJM["/"]]: toKey("keypad_period"),
      [UJM[";"]]: toKey("keypad_hyphen"),
      g: [...terminateMode("SPECIAL"), toKey("g", "shift")],
      i: toKey("keypad_8"),
      j: toKey("keypad_4"),
      k: toKey("keypad_5"),
      l: toKey("keypad_6"),
      m: toKey("keypad_1"),
      o: toKey("keypad_9"),
      u: toKey("keypad_7"),
      [UJM.enter]: toKey("keypad_0"),
      [UJM.半全]: terminateMode("SPECIAL"),
      [UJM[":"]]: [...terminateMode("SPECIAL"), toKey("japanese_kana")],
    },
  ]);
