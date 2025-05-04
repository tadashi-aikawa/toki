import {
  ifApp,
  ifInputSource,
  layer,
  map,
  ModifierParam,
  rule,
  ToEvent,
  toKey,
  ToKeyParam,
  toNotificationMessage,
  toRemoveNotificationMessage,
  toSetVar,
  withModifier,
  writeToProfile,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";

const MODE_NOTIFICATION_ID = "mode_notification_id";

type Mode = "NORMAL" | "SPECIAL";
const terminateMode = (mode: Mode) => [
  toSetVar(mode, 0),
  toSetVar("__layer", 0),
  toRemoveNotificationMessage(MODE_NOTIFICATION_ID),
];
const withTerminateMode = (mode: Mode, toEvent: ToEvent) => [
  toEvent,
  ...terminateMode(mode),
];
const startMode = (mode: Mode) => [
  toSetVar(mode, 1),
  toSetVar("__layer", 1),
  toNotificationMessage(MODE_NOTIFICATION_ID, mode),
];
const changeMode = (from: Mode, to: Mode) => [
  toSetVar(from, 0),
  toSetVar(to, 1),
  toNotificationMessage(MODE_NOTIFICATION_ID, to),
];

const appIdentifierMapper = {
  Ghostty: "com.mitchellh.ghostty",
  "Google Chrome": "com.google.Chrome",
} as const;
type AppName = keyof typeof appIdentifierMapper;
const App = {
  is: (appName: AppName) => ifApp(appIdentifierMapper[appName]),
  not: (appName: AppName) => ifApp(appIdentifierMapper[appName]).unless(),
};

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
  ":": ["quote"],
  ";": ["semicolon"],
  "<-": ["left_arrow"],
  "->": ["right_arrow"],
  "down": ["down_arrow"],
  "up": ["up_arrow"],
  "del": ["delete_or_backspace", "fn"],
  "bs": ["delete_or_backspace"],
  "無変換": ["grave_accent_and_tilde"],
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

/**
 * 基本的に先に定義した方が採用されるので注意
 * 条件付きやmodeの設定は先に記載すること
 */
writeToProfile("Default profile", [
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

  // NORMALモード (caps_lockは使わないと判断した捨てキー)
  layer("caps_lock", "NORMAL").leaderMode({
    sticky: true,
  })
    .manipulators([
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
        "l": toJKeys("->", 5),
        "h": toJKeys("<-", 5),
      }),
      // 特殊
      map(...JM[":"]).to(withTerminateMode("NORMAL", toKey("japanese_kana"))),
      map(",").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map("m").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map("escape").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map(...JM.無変換).to(
        withTerminateMode("NORMAL", toKey("japanese_eisuu")),
      ),
      // モード切り替え
      map("r").to(changeMode("NORMAL", "SPECIAL")),
    ]),

  // SPECIALモード (caps_lockは使わないと判断した捨てキー)
  layer("caps_lock", "SPECIAL").leaderMode({
    sticky: true,
  })
    .manipulators([
      {
        "m": toKey("keypad_1"),
        ",": toKey("keypad_2"),
        ".": toKey("keypad_3"),
        "j": toKey("keypad_4"),
        "k": toKey("keypad_5"),
        "l": toKey("keypad_6"),
        "u": toKey("keypad_7"),
        "i": toKey("keypad_8"),
        "o": toKey("keypad_9"),
        "return_or_enter": toKey("keypad_0"),
      },
      // 特殊
      map(...JM[":"]).to(withTerminateMode("SPECIAL", toKey("japanese_kana"))),
      map("g").to(withTerminateMode("SPECIAL", toKey("g", "shift"))),
      // モード切り替え
      map(...JM.無変換).to(terminateMode("SPECIAL")),
    ]),

  rule("default").manipulators([
    map("escape").to([toKey("escape"), toKey("japanese_eisuu")]),
    map(...JM.無変換).to(
      startMode("NORMAL"),
    ),

    // Control
    withModifier("control")([
      {
        "8": toJKey("{"),
        "9": toJKey("}"),
      },
      map("a").to("a", "command").condition(App.not("Ghostty")),
      map("t").to("t", "command").condition(App.not("Ghostty")),
      map("l").to("l", "command").condition(App.not("Ghostty")),
    ]),

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
]);
