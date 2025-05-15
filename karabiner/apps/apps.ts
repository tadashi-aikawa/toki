import {
  ConditionBuilder,
  ifApp,
  withCondition,
} from "https://deno.land/x/karabinerts@1.31.0/index.ts";

const appIdentifierMapper = {
  Ghostty: "com.mitchellh.ghostty",
  "Google Chrome": "com.google.Chrome",
  Slack: "com.tinyspeck.slackmacgap",
  Obsidian: "md.obsidian",
  Finder: "com.apple.finder",
  VSCode: "com.microsoft.VSCode",
  Kitty: "net.kovidgoyal.kitty",
  WezTerm: "com.github.wez.wezterm",
} as const;

export type AppName = keyof typeof appIdentifierMapper;

export const App = {
  is: (appName: AppName) => ifApp(appIdentifierMapper[appName]),
  not: (appName: AppName) => ifApp(appIdentifierMapper[appName]).unless(),
};

type Manipulators = Parameters<ReturnType<typeof withCondition>>[0];
export const withOrConditions = (
  conditions: ConditionBuilder[],
  manipulators: Manipulators,
) => conditions.map((cond) => withCondition(cond)(manipulators));

/**
 * ターミナルがアクティブなときのキーバインドを設定する
 */
export const withinTerminal = (manipulators: Manipulators) =>
  withOrConditions(
    [App.is("Ghostty"), App.is("Kitty"), App.is("WezTerm"), App.is("VSCode")],
    manipulators,
  );

/**
 * ターミナルではないときのキーバインドを設定する
 */
export const withoutTerminal = (manipulators: Manipulators) =>
  withCondition(
    App.not("Ghostty"),
    App.not("Kitty"),
    App.not("WezTerm"),
    App.not("VSCode"),
  )(
    manipulators,
  );
