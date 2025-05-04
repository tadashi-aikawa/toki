import {
  layer,
  map,
  ModifierParam,
  rule,
  ToEvent,
  toKey,
  ToKeyParam,
  toRemoveNotificationMessage,
  toSetVar,
  withModifier,
  writeToProfile,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";

type Mode = "NORMAL";
const withTerminateMode = (mode: Mode, toEvent: ToEvent) => [
  toEvent,
  toSetVar(mode, 0),
  toSetVar("__layer", 0),
  toRemoveNotificationMessage(`layer-${mode}`),
];

const JM = {
  "{": ["close_bracket", "shift"],
  "}": ["backslash", "shift"],
  "^": ["equal_sign"],
  "#": ["3", "shift"],
  "$": ["4", "shift"],
  "~": ["equal_sign", "shift"],
  "_": ["international1", "shift"],
  "|": ["international3", "shift"],
  "`": ["open_bracket", "shift"],
  "!": ["1", "shift"],
  "&": ["6", "shift"],
  '"': ["2", "shift"],
  "'": ["7", "shift"],
  "(": ["8", "shift"],
  ")": ["9", "shift"],
  "=": ["hyphen", "shift"],
  " ": ["spacebar"],
  ";": ["semicolon"],
  "<-": ["left_arrow"],
  "->": ["right_arrow"],
  "down": ["down_arrow"],
  "up": ["up_arrow"],
  "del": ["delete_or_backspace", "fn"],
  "bs": ["delete_or_backspace"],
} as const satisfies Record<string, [ToKeyParam, ModifierParam?]>;

// as [any] はdeno lint error回避
type JKey = keyof typeof JM;
const toJKey = (key: JKey, repeat: number = 1) =>
  [...Array(repeat).keys()].map(
    (_) => toKey(...JM[key] as [any]),
  );

const toJKeys = (...keys: JKey[]) => keys.flatMap(toJKey);

writeToProfile("Default profile", [
  rule("default").manipulators([
    map("8", "control").to(...JM["{"]),
    map("9", "control").to(...JM["}"]),
  ]),

  // ; combination
  layer(";").leaderMode().manipulators({
    a: toJKey("^"),
    d: toJKey("#"),
    e: toJKeys(" ", "=", " "),
    r: toJKeys(" ", "=", "=", " "),
    k: toJKeys("`", "`", "<-"),
    f: toJKey("$"),
    h: toJKey("~"),
    l: toJKey("_"),
    o: toJKey("|"),
    z: toJKey("!"),
    g: toJKey("&"),
    m: toJKey('"'),
    v: toJKey("'"),
    w: toKey("w", "control"), // ctrl+w
    u: toJKeys('"', '"', "<-"),
    s: toJKeys("(", ")", "<-"),
    i: toJKeys("{", "}", "<-"),
    ";": toJKey(";"),
  }),

  // NORMALモード
  layer("grave_accent_and_tilde", "NORMAL").leaderMode({
    sticky: true,
  })
    .notification(
      "NORMAL",
    ).manipulators([
      {
        j: toJKey("down"),
        k: toJKey("up"),
        l: toJKey("->"),
        h: toJKey("<-"),
        a: toKey("home"),
        ";": toKey("end"),
        f: toKey("home", "control"),
        u: toJKey("bs"),
        o: toJKey("del"),
        c: toKey("c", "command"),
        v: toKey("v", "command"),
      },
      // Shift
      withModifier("shift")({
        "f": toKey("end", "control"),
        "j": toJKey("down", 25),
        "k": toJKey("up", 25),
        "l": toJKey("->", 15),
        "h": toJKey("<-", 15),
        "u": toJKey("bs", 15),
        "o": toJKey("del", 15),
      }),
      // Control
      withModifier("control")({
        "j": toJKey("down", 5),
        "k": toJKey("up", 5),
        "l": toJKey("->", 5),
        "h": toJKey("<-", 5),
        "u": toJKey("bs", 5),
        "o": toJKey("del", 5),
      }),
      // 特殊
      map("quote").to(withTerminateMode("NORMAL", toKey("japanese_kana"))),
      map(",").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map("m").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map("escape").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map("grave_accent_and_tilde").to(
        withTerminateMode("NORMAL", toKey("japanese_eisuu")),
      ),
    ]),
  rule("ESC").manipulators([
    map("escape").to([toKey("escape"), toKey("japanese_eisuu")]),
  ]),
]);
