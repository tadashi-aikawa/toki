import {
  layer,
  map,
  rule,
  ToEvent,
  toKey,
  toRemoveNotificationMessage,
  toSetVar,
  writeToProfile,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";

type Mode = "NORMAL";
const withTerminateMode = (mode: Mode, toEvent: ToEvent) => [
  toEvent,
  toSetVar(mode, 0),
  toSetVar("__layer", 0),
  toRemoveNotificationMessage(`layer-${mode}`),
];

writeToProfile("Default profile", [
  layer(";").leaderMode().manipulators({
    a: toKey("equal_sign"), // ^
    d: toKey("3", "shift"), // #
    e: [toKey("spacebar"), toKey("hyphen", "shift"), toKey("spacebar")], // <space>=<space>
    r: [
      toKey("spacebar"),
      toKey("hyphen", "shift"),
      toKey("hyphen", "shift"),
      toKey("spacebar"),
    ], // <space>==<space>
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
    w: toKey("w", "control"), // ctrl+w
    u: [toKey("2", "shift"), toKey("2", "shift"), toKey("left_arrow")], // ""
    s: [toKey("8", "shift"), toKey("9", "shift"), toKey("left_arrow")], // ()
    i: [
      toKey("close_bracket", "shift"),
      toKey("backslash", "shift"),
      toKey("left_arrow"),
    ], // {}
    ";": toKey("semicolon"),
  }),

  // NORMALモード
  layer("grave_accent_and_tilde", "NORMAL").leaderMode({
    sticky: true,
    escape: ["grave_accent_and_tilde", "escape"],
  })
    .notification(
      "NORMAL",
    ).manipulators([
      map("j").to("down_arrow"),
      map("k").to("up_arrow"),
      map("h").to("left_arrow"),
      map("l").to("right_arrow"),
      map("a").to("home"),
      map(";").to("end"),
      map("f").to("home", "control"),
      map("f", "shift").to("end", "control"),
      map("u").to("delete_or_backspace"),
      map("o").to("delete_or_backspace", "fn"),

      map("quote").to(withTerminateMode("NORMAL", toKey("japanese_kana"))),
    ]),
  rule("ESC").manipulators([
    map("escape").to([toKey("escape"), toKey("japanese_eisuu")]),
  ]),
]);
