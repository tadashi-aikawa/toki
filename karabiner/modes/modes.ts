import {
  toNotificationMessage,
  toRemoveNotificationMessage,
  toSetVar,
} from "karabiner.ts";

const MODE_NOTIFICATION_ID = "mode_notification_id";

type Mode = "NORMAL" | "RANGE" | "SPECIAL";
export const terminateMode = (mode: Mode) => [
  toRemoveNotificationMessage(MODE_NOTIFICATION_ID),
  toSetVar(mode, 0),
  toSetVar("__layer", 0),
];
export const startMode = (mode: Mode) => [
  toNotificationMessage(MODE_NOTIFICATION_ID, mode),
  toSetVar(mode, 1),
  toSetVar("__layer", 1),
];
export const changeMode = (from: Mode, to: Mode) => [
  toNotificationMessage(MODE_NOTIFICATION_ID, to),
  toSetVar(from, 0),
  toSetVar(to, 1),
];
