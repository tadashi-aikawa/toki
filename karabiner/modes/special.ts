import { layer, toKey } from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { toJKeyWith, UJM, UNUSED_KEY } from "../utils/keys.ts";
import { terminateMode } from "./modes.ts";

export const specialModeDefinitions = layer(UNUSED_KEY, "SPECIAL")
  .leaderMode({ sticky: true })
  .manipulators([
    {
      ",": toKey("keypad_2"),
      ".": toKey("keypad_3"),
      [UJM["/"]]: toKey("keypad_period"),
      [UJM[";"]]: toKey("keypad_hyphen"),
      a: toJKeyWith("<-", ["control", "option", "shift"]), // 左1/4へウィンドウサイズ変更
      d: toJKeyWith("enter", ["control", "option"]), // ウィンドウサイズをフルにする
      e: toJKeyWith("->", ["control", "option"]), // 右半分へウィンドウサイズ変更
      f: toJKeyWith("->", ["control", "option", "shift"]), // 右1/4へウィンドウサイズ変更
      g: [...terminateMode("SPECIAL"), toKey("g", "shift")],
      i: toKey("keypad_8"),
      j: toKey("keypad_4"),
      k: toKey("keypad_5"),
      l: toKey("keypad_6"),
      m: toKey("keypad_1"),
      o: toKey("keypad_9"),
      s: toKey("c", ["control", "option"]), // 中央1/2へウィンドウサイズ変更
      t: toJKeyWith("->", ["control", "option", "command"]), // 次のスクリーンへウィンドウを移動
      u: toKey("keypad_7"),
      w: toJKeyWith("<-", ["control", "option"]), // 左半分へウィンドウサイズ変更
      [UJM.enter]: toKey("keypad_0"),
      [UJM.半全]: terminateMode("SPECIAL"),
      [UJM[":"]]: [...terminateMode("SPECIAL"), toKey("japanese_kana")],
    },
  ]);
