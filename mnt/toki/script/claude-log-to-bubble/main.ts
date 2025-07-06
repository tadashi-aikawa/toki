#!/usr/bin/env -S deno run --allow-read --allow-env

import { join } from "https://deno.land/std@0.208.0/path/mod.ts";

interface UserLog {
  type: "user";
  isMeta?: boolean;
  isSidechain: boolean;
  parentUuid: string | null;
  message: {
    role: "user";
    content: string | Content[];
  };
}
interface AssistantLog {
  type: "assistant";
  isMeta?: boolean;
  isSidechain: boolean;
  parentUuid: string | null;
  message: {
    type: "message";
    content: Content[];
  };
}
interface SummaryLog {
  type: "summary";
}
type Log = UserLog | AssistantLog | SummaryLog;

interface TextContent {
  type: "text";
  text: string;
}
interface ToolUserContent {
  type: "tool_use";
  id: string;
  name: string;
  input: {
    command: string;
    description: string;
  };
}
interface ToolResultContent {
  type: "tool_result";
  too_use_id: string;
  content: string;
  is_error: boolean;
}
type Content = TextContent | ToolUserContent | ToolResultContent;

function processCommandTags(content: string): string {
  // command-messageタグを除去
  content = content.replace(/<command-message>.*?<\/command-message>\n?/g, "");

  // command-nameタグを強調表示に変換し、改行を追加
  content = content.replace(
    /<command-name>(.*?)<\/command-name>/g,
    "**`$1`**\n",
  );

  return content;
}

function main() {
  const specifiedFile = Deno.args[0];
  let latestLog: string;

  const claudeBaseDir = join(Deno.env.get("HOME") || "", ".claude/projects");
  try {
    Deno.statSync(claudeBaseDir);
  } catch {
    console.error(
      `Claude Code設定ディレクトリが見つかりません: ${claudeBaseDir}`,
    );
    Deno.exit(1);
  }

  const currentPath = Deno.cwd()
    .replace(/^\//, "-")
    .replaceAll("/", "-")
    .replaceAll(".", "-");
  const projectDir = join(claudeBaseDir, currentPath);

  if (specifiedFile) {
    latestLog = `${projectDir}/${specifiedFile}`;
    try {
      Deno.statSync(latestLog);
    } catch {
      console.error(`指定されたファイルが見つかりません: ${latestLog}`);
      Deno.exit(1);
    }
  } else {
    try {
      const entries = Array.from(Deno.readDirSync(projectDir))
        .filter((entry) => entry.name.endsWith(".jsonl"))
        .map((entry) => {
          const stat = Deno.statSync(join(projectDir, entry.name));
          return { name: entry.name, mtime: stat.mtime };
        })
        .sort((a, b) => (b.mtime?.getTime() || 0) - (a.mtime?.getTime() || 0));

      if (entries.length === 0) {
        console.error("会話ログファイルが見つかりません");
        Deno.exit(1);
      }

      latestLog = join(projectDir, entries[0].name);
    } catch {
      console.error("会話ログファイルが見つかりません");
      Deno.exit(1);
    }
  }

  let isFirstTargetLog = true;
  const contents = Deno.readTextFileSync(latestLog)
    .trim()
    .split("\n")
    .map((line) => {
      const log = JSON.parse(line) as Log;
      if (log.type === "summary") {
        return null;
      }
      // slash commandは無視(のはず)
      if (log.isMeta) {
        return null;
      }
      // sidechainは無視
      if (log.isSidechain) {
        return null;
      }
      // 親UUIDがないログは最初のログのみ対象
      if (log.parentUuid == null && !isFirstTargetLog) {
        return null;
      }

      isFirstTargetLog = false;

      const texts =
        typeof log.message.content === "string"
          ? [processCommandTags(log.message.content)]
          : log.message.content
              .filter((content) => content.type === "text")
              .map((x) => x.text)
              .map((x) =>
                x === "[Request interrupted by user for tool use]"
                  ? "**異議あり** (もしくは中断指令)"
                  : processCommandTags(x),
              );
      if (texts.length === 0) {
        return null;
      }

      const header =
        log.type === "user"
          ? `[!right-bubble] ![[minerva-face-right.webp]]`
          : `[!left-bubble] ![[claude-san-face.webp]]`;

      const messages = texts
        .map((m) => `> ${m}`.replaceAll(/\n/g, "\n> "))
        .join("\n");

      return `> ${header}
${messages}`;
    })
    .filter((x) => x !== null);

  console.log(contents.join("\n\n"));
}

if (import.meta.main) {
  main();
}
