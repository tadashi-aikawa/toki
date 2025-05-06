import { ifApp } from "https://deno.land/x/karabinerts@1.31.0/index.ts";

const appIdentifierMapper = {
  Ghostty: "com.mitchellh.ghostty",
  "Google Chrome": "com.google.Chrome",
  Slack: "com.tinyspeck.slackmacgap",
  Obsidian: "md.obsidian",
} as const;

export type AppName = keyof typeof appIdentifierMapper;

export const App = {
  is: (appName: AppName) => ifApp(appIdentifierMapper[appName]),
  not: (appName: AppName) => ifApp(appIdentifierMapper[appName]).unless(),
};
