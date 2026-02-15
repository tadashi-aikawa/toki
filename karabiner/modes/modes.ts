import {
  to$,
  toSetVar,
} from "karabiner.ts";

type Mode = "NORMAL" | "RANGE" | "SPECIAL";
const toHammerspoonMode = (mode: Mode | "DEFAULT") =>
  to$(
    `/usr/bin/open -g "hammerspoon://karabiner-mode?mode=${mode}" >/dev/null 2>&1`,
  );

export const terminateMode = (mode: Mode) => [
  toSetVar(mode, 0),
  toSetVar("__layer", 0),
  toHammerspoonMode("DEFAULT"),
];
export const startMode = (mode: Mode) => [
  toSetVar(mode, 1),
  toSetVar("__layer", 1),
  toHammerspoonMode(mode),
];
export const changeMode = (from: Mode, to: Mode) => [
  toSetVar(from, 0),
  toSetVar(to, 1),
  toHammerspoonMode(to),
];
