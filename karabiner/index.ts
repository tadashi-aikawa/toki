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
  "%": ["5", "shift"],
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
const toJKey = (key: JKey) => toKey(...JM[key] as [any]);

const toJKeys = (...args: JKey[] | [JKey, repeat: number]) => {
  if (typeof args[1] === "number") {
    return [...Array(args[1]).keys()].map(
      (_) => toKey(...JM[args[0]] as [any]),
    );
  }

  const keys = args as JKey[];
  return keys.map(toJKey);
};

writeToProfile("Default profile", [
  rule("default").manipulators([
    map("8", "control").to(...JM["{"]),
    map("9", "control").to(...JM["}"]),

    // Control
    withModifier("control")({
      "8": toJKey("{"),
      "9": toJKey("}"),
    }),

    // Option
    withModifier("option")({
      "l": toKey("tab", "control"),
      "h": toKey("tab", ["control", "shift"]),
      "tab": toKey("tab", "command"),
    }),

    // Command
    withModifier("command")({
      "tab": toKey("up_arrow", "control"),
    }),
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
    p: toJKey("%"),
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
        q: toKey("w", "command"),
      },
      // Shift
      withModifier("shift")({
        "f": toKey("end", "control"),
        "j": toJKeys("down", 25),
        "k": toJKeys("up", 25),
        "l": toJKeys("->", 10),
        "h": toJKeys("<-", 10),
        "u": toJKeys("bs", 5),
        "o": toJKeys("del", 5),
      }),
      // Control
      withModifier("control")({
        "j": toJKeys("down", 5),
        "k": toJKeys("up", 5),
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
