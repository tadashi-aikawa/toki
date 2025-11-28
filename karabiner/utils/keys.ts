import { ModifierParam, toKey, ToKeyParam } from "karabiner.ts";

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
  "_": "international1",
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
  PrintScreen: "print_screen",
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

// deno-lint-ignore no-explicit-any
export const toJKey = (key: JKey) => toKey(...(JM[key] as [any]));

export const toJKeyWith = (
  key: JKey,
  modifier: ModifierParam,
  repeat?: number,
) => {
  const nonModifierKey = JM[key][0];
  const mod = JM[key][1] ? [JM[key][1]] : [];
  const toKeyArgs = [nonModifierKey, [...mod, ...[modifier].flat()]];
  // deno-lint-ignore no-explicit-any
  const retKey = toKey(...(toKeyArgs as [any]));

  return repeat ? [...Array(repeat).keys()].map((_) => retKey) : retKey;
};

export const toJKeys = (...args: JKey[] | [JKey, repeat: number]) => {
  if (typeof args[1] === "number") {
    return [...Array(args[1]).keys()].map((_) =>
      // deno-lint-ignore no-explicit-any
      toKey(...(JM[args[0]] as [any]))
    );
  }

  const keys = args as JKey[];
  return keys.map(toJKey);
};

export const UNUSED_KEY = "caps_lock";
