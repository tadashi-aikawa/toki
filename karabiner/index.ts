import {
  map,
  rule,
  toKey,
  withCondition,
  withModifier,
  writeToProfile,
} from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import { normalModeDefinitions } from "./modes/normal.ts";
import { rangeModeDefinitions } from "./modes/range.ts";
import { specialModeDefinitions } from "./modes/special.ts";
import { App } from "./apps/apps.ts";
import { commandJLeaderDefinitions } from "./leaders/commandJ.ts";
import { semicolonLeaderDefinitions } from "./leaders/semicolon.ts";
import { defaultRule } from "./modes/base.ts";
import { UJM } from "./utils/keys.ts";

/**
 * 基本的に先に定義した方が採用されるので注意
 * 条件付きやmodeの設定は先に記載すること
 */
writeToProfile("Default profile", [
  // Most prioritize
  rule("switch control <-> command").manipulators([
    // Ghosttyだけはleft_controlがleft_commandのように振る舞うためマッピングを分岐させる必要がある
    withCondition(App.is("Ghostty"))([
      withModifier("command")({
        q: toKey("f13", "option"), // raycast起動用
        r: toKey("f14", "command"), // raycast clipboard起動用
        [UJM["/"]]: toKey("f15", "command"), // raycast emoji起動用
      }),
      withModifier("control")({
        q: toKey("q", "command"),
      }),
    ]),
    withCondition(App.not("Ghostty"))([
      map("left_control").to("left_command"),
      map("left_command").to("left_control"),
      map("left_control", "shift").to("left_command", "shift"),
      map("left_command", "shift").to("left_control", "shift"),
      withModifier("control")({
        q: toKey("f13", "option"), // raycast起動用
        r: toKey("f14", "command"), // raycast clipboard起動用
        [UJM["/"]]: toKey("f15", "command"), // raycast emoji起動用
      }),
    ]),
  ]),

  // Modes
  normalModeDefinitions,
  rangeModeDefinitions,
  specialModeDefinitions,

  // Leaders
  ...semicolonLeaderDefinitions,
  ...commandJLeaderDefinitions,

  defaultRule,
]);
