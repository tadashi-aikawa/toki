import {
  layer,
  toKey,
  writeToProfile,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";

writeToProfile("Default profile", [
  layer(";").leaderMode().notification().manipulators({
    a: toKey("equal_sign"), // ^
    d: toKey("3", "shift"), // #
    e: [toKey("spacebar"), toKey("hyphen", "shift"), toKey("spacebar")], // <space>=<space>
    r: [
      toKey("spacebar"),
      toKey("hyphen", "shift"),
      toKey("hyphen", "shift"),
      toKey("spacebar"),
    ], // <space>==<space>
    w: [
      toKey("spacebar"),
      toKey("1", "shift"),
      toKey("hyphen", "shift"),
      toKey("spacebar"),
    ], // <space>!=<space>
    k: [
      toKey("open_bracket", "shift"),
      toKey("open_bracket", "shift"),
      toKey("left_arrow"),
    ], // ``
    f: toKey("4", "shift"), // $
    h: toKey("equal_sign", "shift"), // ~
    l: toKey("international1", "shift"), // _
    o: toKey("international3", "shift"), // |
    z: toKey("1", "shift"), // !
    g: toKey("6", "shift"), // &
    m: toKey("2", "shift"), // "
    v: toKey("7", "shift"), // '
    u: [toKey("2", "shift"), toKey("2", "shift"), toKey("left_arrow")], // ""
    s: [toKey("8", "shift"), toKey("9", "shift"), toKey("left_arrow")], // ()
    i: [
      toKey("close_bracket", "shift"),
      toKey("backslash", "shift"),
      toKey("left_arrow"),
    ], // {}
    ";": toKey("semicolon"),
  }),
]);
