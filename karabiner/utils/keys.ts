import {
  ModifierParam,
  toKey,
  ToKeyParam,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";

/**
 * 単一のキーで成立するJISキーマッピング
 */
export const UJM = {
  "^": "equal_sign",
  " ": "spacebar",
  ":": "quote",
  ";": "semicolon",
  ",": "comma",
  "/": "slash",
  "<-": "left_arrow",
  "->": "right_arrow",
  "[": "close_bracket",
  "]": "non_us_pound",
  down: "down_arrow",
  up: "up_arrow",
  bs: "delete_or_backspace",
  home: "home",
  end: "end",
  ESC: "escape",
  enter: "return_or_enter",
  tab: "tab",
  半全: "grave_accent_and_tilde",
  かな: "japanese_kana",
  英数: "japanese_eisuu",
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
export const JM = {
  "{": ["close_bracket", "shift"],
  "}": ["backslash", "shift"],
  "~": ["equal_sign", "shift"],
  _: ["international1", "shift"],
  "|": ["international3", "shift"],
  "`": ["open_bracket", "shift"],
  "!": ["1", "shift"],
  '"': ["2", "shift"],
  "#": ["3", "shift"],
  $: ["4", "shift"],
  "%": ["5", "shift"],
  "&": ["6", "shift"],
  "'": ["7", "shift"],
  "(": ["8", "shift"],
  ")": ["9", "shift"],
  "=": ["hyphen", "shift"],
  del: ["delete_or_backspace", "fn"],
  ...toSingleTupleMap(UJM),
} as const satisfies Record<string, [ToKeyParam, ModifierParam?]>;

// as [any] はdeno lint error回避
type JKey = keyof typeof JM;
// as [any] はdeno lint error回避
type UniJMKey = keyof typeof UJM;

export const toJKey = (key: JKey) => toKey(...(JM[key] as [any]));
export const toJKeyWith = (
  key: UniJMKey,
  modifier: ModifierParam,
  repeat?: number,
) =>
  repeat
    ? [...Array(repeat).keys()].map((_) =>
      toKey(...(JM[key] as [any]), modifier)
    )
    : toKey(...(JM[key] as [any]), modifier);
export const toJKeys = (...args: JKey[] | [JKey, repeat: number]) => {
  if (typeof args[1] === "number") {
    return [...Array(args[1]).keys()].map((_) =>
      toKey(...(JM[args[0]] as [any]))
    );
  }

  const keys = args as JKey[];
  return keys.map(toJKey);
};

export const UNUSED_KEY = "caps_lock";
