import {
  map,
  mapDoubleTap,
  rule,
  toKey,
  withModifier,
  writeToProfile,
} from "karabiner.ts";
import { normalModeDefinitions } from "./modes/normal.ts";
import { rangeModeDefinitions } from "./modes/range.ts";
import { specialModeDefinitions } from "./modes/special.ts";
import { withinTerminal, withoutTerminal } from "./apps/apps.ts";
import { commandJLeaderDefinitions } from "./leaders/commandJ.ts";
import { semicolonLeaderDefinitions } from "./leaders/semicolon.ts";
import { defaultRule } from "./modes/default.ts";
import { UJM } from "./utils/keys.ts";

/**
 * 基本的に先に定義した方が採用されるので注意
 * 条件付きやmodeの設定は先に記載すること
 */
writeToProfile("Default profile", [
  // Most prioritize
  rule("switch control <-> command").manipulators([
    // ターミナルだけはleft_controlがleft_commandのように振る舞うためマッピングを分岐させる必要がある
    ...withinTerminal([
      map("left_control").to("left_control"),
      map("left_command").to("left_command").toIfAlone("f19", "option"), // 単押しでミッションコントロール

      withModifier("command")({
        q: toKey("f13", "option"), // raycast起動用
        r: toKey("f14", "command"), // raycast clipboard起動用
        [UJM["/"]]: toKey("f15", "command"), // raycast emoji起動用
      }),
      withModifier("control")({
        q: toKey("q", "command"),
      }),
    ]),
    withoutTerminal([
      // 二度押しで(Obsidian -> エディタフォーカス)(Chrome -> 要素の選択)
      mapDoubleTap("left_control").to("c", ["command", "shift"]).singleTap(
        toKey("left_command"),
      ),
      map("left_command").to("left_control").toIfAlone("f19", "option"), // 単押しでミッションコントロール
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
