import {
  ifApp,
  layer,
  ModifierParam,
  rule,
  toKey,
  ToKeyParam,
  toNotificationMessage,
  toPaste,
  toRemoveNotificationMessage,
  toSetVar,
  withCondition,
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

/**
 * 単一のキーで成立するJISキーマッピング
 */
const UJM = {
  "^": "equal_sign",
  " ": "spacebar",
  ":": "quote",
  ";": "semicolon",
  "/": "keypad_slash",
  "<-": "left_arrow",
  "->": "right_arrow",
  "down": "down_arrow",
  "up": "up_arrow",
  "bs": "delete_or_backspace",
  "home": "home",
  "end": "end",
  "ESC": "escape",
  "enter": "return_or_enter",
  "tab": "tab",
  "半全": "grave_accent_and_tilde",
  "かな": "japanese_kana",
  "英数": "japanese_eisuu",
} as const satisfies Record<string, ToKeyParam>;

function toSingleTupleMap<T extends Record<string, string>>(map: T) {
  const out = {} as { [K in keyof T]: [T[K]] };
  for (const k in map) {
    out[k] = [map[k]] as const;
  }
  return out;
}

/**
 * JISキーマッピング
 */
const JM = {
  "{": ["close_bracket", "shift"],
  "}": ["backslash", "shift"],
  "~": ["equal_sign", "shift"],
  "_": ["international1", "shift"],
  "|": ["international3", "shift"],
  "`": ["open_bracket", "shift"],
  "!": ["1", "shift"],
  '"': ["2", "shift"],
  "#": ["3", "shift"],
  "$": ["4", "shift"],
  "%": ["5", "shift"],
  "&": ["6", "shift"],
  "'": ["7", "shift"],
  "(": ["8", "shift"],
  ")": ["9", "shift"],
  "=": ["hyphen", "shift"],
  "del": ["delete_or_backspace", "fn"],
  ...toSingleTupleMap(UJM),
} as const satisfies Record<string, [ToKeyParam, ModifierParam?]>;

// as [any] はdeno lint error回避
type JKey = keyof typeof JM;
// as [any] はdeno lint error回避
type UniJMKey = keyof typeof UJM;

const toJKey = (key: JKey) => toKey(...JM[key] as [any]);
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

const UNUSED_KEY = "caps_lock";

/**
 * 基本的に先に定義した方が採用されるので注意
 * 条件付きやmodeの設定は先に記載すること
 */
writeToProfile("Default profile", [
  layer(UNUSED_KEY, "NORMAL").leaderMode({
    sticky: true,
  })
    .manipulators([
      withCondition(App.is("Ghostty"))([
        {
          ";": toKey("end"),
          a: toKey("home"),
          f: toJKeyWith("home", "control"),
        },
        withModifier("shift")({
          f: toJKeyWith("end", "control"),
        }),
      ]),

      {
        ",": [...terminateMode("NORMAL"), toKey("japanese_eisuu")],
        ".": [toJKey("="), ...terminateMode("NORMAL")],
        ";": toJKeyWith("->", "command"),
        [UJM.ESC]: [...terminateMode("NORMAL"), toKey("japanese_eisuu")],
        [UJM.半全]: [...terminateMode("NORMAL"), toKey("japanese_eisuu")],
        [UJM[":"]]: [...terminateMode("NORMAL"), toKey("japanese_kana")],
        a: toJKeyWith("<-", "command"),
        c: toKey("c", "command"),
        d: toJKey("bs"),
        e: toJKeyWith("<-", "command"),
        f: toJKeyWith("up", "command"),
        g: changeMode("NORMAL", "RANGE"),
        h: toJKey("<-"),
        j: toJKey("down"),
        k: toJKey("up"),
        l: toJKey("->"),
        m: [...terminateMode("NORMAL"), toKey("japanese_eisuu")],
        o: toJKey("del"),
        q: toKey("w", "command"),
        r: changeMode("NORMAL", "SPECIAL"),
        u: toJKey("bs"),
        v: toKey("v", "command"),
        y: toKey("y", "command"),
        z: toKey("z", "command"),
      },

      withModifier("shift")({
        f: toJKeyWith("down", "command"),
        h: toJKeys("<-", 10),
        j: toJKeys("down", 25),
        k: toJKeys("up", 25),
        l: toJKeys("->", 10),
        o: toJKeys("del", 5),
        u: toJKeys("bs", 5),
      }),
      withModifier("control")({
        e: toJKeyWith("->", "command"),
        h: toJKeys("<-", 5),
        j: toJKeys("down", 5),
        k: toJKeys("up", 5),
        l: toJKeys("->", 5),
      }),
    ]),

  layer(UNUSED_KEY, "RANGE").leaderMode({
    sticky: true,
  })
    .manipulators([
      withCondition(App.is("Ghostty"))([
        {
          ";": toJKeyWith("end", "shift"),
          a: toJKeyWith("home", "shift"),
          f: toJKeyWith("home", ["control", "shift"]),
        },
        withModifier("shift")({
          f: toJKeyWith("end", ["control", "shift"]),
        }),
      ]),

      {
        ";": toJKeyWith("->", ["command", "shift"]),
        [UJM.ESC]: [...terminateMode("RANGE"), toKey("japanese_eisuu")],
        [UJM.半全]: [...terminateMode("RANGE"), toKey("japanese_eisuu")],
        a: toJKeyWith("<-", ["command", "shift"]),
        c: [...changeMode("RANGE", "NORMAL"), toKey("c", "command")],
        d: [...changeMode("RANGE", "NORMAL"), toJKey("bs")],
        f: toJKeyWith("up", ["command", "shift"]),
        g: changeMode("RANGE", "NORMAL"),
        h: toJKeyWith("<-", "shift"),
        j: toJKeyWith("down", "shift"),
        k: toJKeyWith("up", "shift"),
        l: toJKeyWith("->", "shift"),
        o: [...changeMode("RANGE", "NORMAL"), toJKey("del")],
        u: [...changeMode("RANGE", "NORMAL"), toJKey("bs")],
        x: [...changeMode("RANGE", "NORMAL"), toKey("x", "command")],
      },

      withModifier("shift")({
        h: toJKeyWith("<-", "shift", 25),
        j: toJKeyWith("down", "shift", 25),
        k: toJKeyWith("up", "shift", 25),
        l: toJKeyWith("->", "shift", 25),
        f: toJKeyWith("down", ["command", "shift"]),
      }),

      withModifier("control")({
        h: toJKeyWith("<-", "shift", 5),
        j: toJKeyWith("down", "shift", 5),
        k: toJKeyWith("up", "shift", 5),
        l: toJKeyWith("->", "shift", 5),
      }),
    ]),

  layer(UNUSED_KEY, "SPECIAL").leaderMode({
    sticky: true,
  })
    .manipulators([
      {
        ",": toKey("keypad_2"),
        ".": toKey("keypad_3"),
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
    ]),

  // ; combination
  layer(";").leaderMode().manipulators({
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
    z: toJKey("!"),
  }),

  rule("default").manipulators([
    withCondition(App.not("Ghostty"))([
      withModifier("control")({
        a: toKey("a", "command"),
        f: toKey("f", "command"),
        l: toKey("l", "command"),
        t: toKey("t", "command"),
      }),
    ]),

    {
      [UJM.ESC]: toJKeys("ESC", "英数"),
      [UJM.半全]: startMode("NORMAL"),
    },

    withModifier("control")([
      {
        "8": toJKey("{"),
        "9": toJKey("}"),
        q: toKey("q", "command"),
      },
    ]),

    withModifier("command")({
      "2": toJKeys("#", "#", " "),
      "3": toJKeys("#", "#", "#", " "),
      "4": toJKeys("#", "#", "#", "#", " "),
      "5": toJKeys("#", "#", "#", "#", "#", " "),
      h: toJKeyWith("tab", ["control", "shift"]),
      l: toJKeyWith("tab", "control"),
      q: toKey("f13", "option"), // raycast起動用
    }),
  ]),
]);
