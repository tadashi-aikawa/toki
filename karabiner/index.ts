import {
  ifApp,
  layer,
  map,
  ModifierParam,
  rule,
  ToEvent,
  toKey,
  ToKeyParam,
  toNotificationMessage,
  toPaste,
  toRemoveNotificationMessage,
  toSetVar,
  withModifier,
  writeToProfile,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";

const MODE_NOTIFICATION_ID = "mode_notification_id";

type Mode = "NORMAL" | "RANGE" | "SPECIAL";
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
  "/": ["keypad_slash"],
  "<-": ["left_arrow"],
  "->": ["right_arrow"],
  "down": ["down_arrow"],
  "up": ["up_arrow"],
  "del": ["delete_or_backspace", "fn"],
  "bs": ["delete_or_backspace"],
  "無変換": ["grave_accent_and_tilde"],
  "home": ["home"],
} as const satisfies Record<string, [ToKeyParam, ModifierParam?]>;

// as [any] はdeno lint error回避
type JKey = keyof typeof JM;
const toJKey = (key: JKey) => toKey(...JM[key] as [any]);

// as [any] はdeno lint error回避
type UniJMKey = {
  [K in JKey]: (typeof JM)[K] extends { length: 1 } ? K : never;
}[JKey];
const toJKeyWith = (key: UniJMKey, modifier: ModifierParam, repeat?: number) =>
  repeat
    ? [...Array(repeat).keys()].map(
      (_) => toKey(...JM[key] as [any], modifier),
    )
    : toKey(...JM[key] as [any], modifier);

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
        u: toJKey("bs"),
        d: toJKey("bs"),
        o: toJKey("del"),
        c: toKey("c", "command"),
        v: toKey("v", "command"),
        q: toKey("w", "command"),
        e: toJKeyWith("<-", "command"),
        z: toKey("z", "command"),
        y: toKey("y", "command"),
      },
      // Shift
      withModifier("shift")({
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
        "e": toJKeyWith("->", "command"),
      }),
      // 特殊
      map("a").to("home").condition(App.is("Ghostty")),
      map("a").to("←", "command").condition(App.not("Ghostty")),
      map(";").to("end").condition(App.is("Ghostty")),
      map(";").to("→", "command").condition(App.not("Ghostty")),
      map("f").to("home", "control").condition(App.is("Ghostty")),
      map("f").to("↑", "command").condition(App.not("Ghostty")),
      map("f", "shift").to("end", "control").condition(App.is("Ghostty")),
      map("f", "shift").to("↓", "command").condition(App.not("Ghostty")),

      map(...JM[":"]).to(withTerminateMode("NORMAL", toKey("japanese_kana"))),
      map(",").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map("m").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map("escape").to(withTerminateMode("NORMAL", toKey("japanese_eisuu"))),
      map(...JM.無変換).to(
        withTerminateMode("NORMAL", toKey("japanese_eisuu")),
      ),
      // モード切り替え
      map("r").to(changeMode("NORMAL", "SPECIAL")),
      map("g").to(changeMode("NORMAL", "RANGE")),
    ]),

  // RANGEモード (caps_lockは使わないと判断した捨てキー)
  layer("caps_lock", "RANGE").leaderMode({
    sticky: true,
  })
    .manipulators([
      {
        j: toJKeyWith("down", "shift"),
        k: toJKeyWith("up", "shift"),
        l: toJKeyWith("->", "shift"),
        h: toJKeyWith("<-", "shift"),
        c: [...changeMode("RANGE", "NORMAL"), toKey("c", "command")],
        x: [...changeMode("RANGE", "NORMAL"), toKey("x", "command")],
        u: [...changeMode("RANGE", "NORMAL"), toJKey("bs")],
        d: [...changeMode("RANGE", "NORMAL"), toJKey("bs")],
        o: [...changeMode("RANGE", "NORMAL"), toJKey("del")],
      },
      // Shift
      withModifier("shift")({
        "j": toJKeyWith("down", "shift", 25),
        "k": toJKeyWith("up", "shift", 25),
        "l": toJKeyWith("->", "shift", 25),
        "h": toJKeyWith("<-", "shift", 25),
      }),
      // Control
      withModifier("control")({
        "j": toJKeyWith("down", "shift", 5),
        "k": toJKeyWith("up", "shift", 5),
        "l": toJKeyWith("->", "shift", 5),
        "h": toJKeyWith("<-", "shift", 5),
      }),
      // 特殊
      map("a").to("home", "shift").condition(App.is("Ghostty")),
      map("a").to("←", ["command", "shift"]).condition(App.not("Ghostty")),
      map(";").to("end", "shift").condition(App.is("Ghostty")),
      map(";").to("→", ["command", "shift"]).condition(App.not("Ghostty")),

      // 特殊
      map("g").to(withTerminateMode("SPECIAL", toKey("g", "shift"))),
      map("f").to("home", ["control", "shift"]).condition(App.is("Ghostty")),
      map("f").to("↑", ["command", "shift"]).condition(App.not("Ghostty")),
      map("f", "shift").to("end", ["control", "shift"]).condition(
        App.is("Ghostty"),
      ),
      map("f", "shift").to("↓", ["command", "shift"]).condition(
        App.not("Ghostty"),
      ),
      // モード切り替え
      map(...JM.無変換).to(
        withTerminateMode("RANGE", toKey("japanese_eisuu")),
      ),
      map("escape").to(withTerminateMode("RANGE", toKey("japanese_eisuu"))),
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

  // ; combination
  layer(";").leaderMode().manipulators({
    a: toJKey("^"),
    c: toJKeys("`", "`", "`"),
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
    t: toPaste(Temporal.Now.plainDateISO().toString()),
    "/": toPaste(Temporal.Now.plainDateISO().toString().replaceAll("-", "/")),
  }),

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
      "2": toJKeys("#", "#", " "),
      "3": toJKeys("#", "#", "#", " "),
      "4": toJKeys("#", "#", "#", "#", " "),
      "5": toJKeys("#", "#", "#", "#", "#", " "),
    }),

    // Command
    withModifier("command")({
      "tab": toKey("up_arrow", "control"),
    }),
  ]),
]);
