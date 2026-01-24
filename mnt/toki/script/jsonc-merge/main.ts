#!/usr/bin/env -S deno run --allow-read --allow-write

import {
  parse as parseJsonc,
  ParseError,
  printParseErrorCode,
} from "npm:jsonc-parser";

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

function mergeDeep(base: unknown, patch: unknown): unknown {
  if (isPlainObject(base) && isPlainObject(patch)) {
    const merged: Record<string, unknown> = { ...base };
    for (const [key, patchValue] of Object.entries(patch)) {
      const baseValue = merged[key];
      merged[key] = mergeDeep(baseValue, patchValue);
    }
    return merged;
  }
  return patch;
}

function parseJsoncText(
  text: string,
  label: string,
): Record<string, unknown> {
  const errors: ParseError[] = [];
  const result = parseJsonc(text, errors, {
    allowTrailingComma: true,
    disallowComments: false,
  });
  if (errors.length > 0) {
    const message = errors
      .map((error) => `${label}: ${printParseErrorCode(error.error)}`)
      .join("\n");
    throw new Error(message);
  }
  if (!isPlainObject(result)) {
    throw new Error(`${label}: オブジェクトが必要です`);
  }
  return result;
}

function readPatchText(raw: string): string {
  if (raw.startsWith("@")) {
    const path = raw.slice(1);
    if (!path) {
      throw new Error("パッチファイルのパスが空です");
    }
    return Deno.readTextFileSync(path);
  }
  return raw;
}

function main(args: string[]): void {
  const [targetPath, patchArg] = args;
  if (!targetPath || !patchArg) {
    console.error(
      "使い方: deno run --allow-read --allow-write main.ts <target.jsonc> <patch or @file>",
    );
    Deno.exit(1);
  }

  const targetText = Deno.readTextFileSync(targetPath);
  const patchText = readPatchText(patchArg);

  const target = parseJsoncText(targetText, targetPath);
  const patch = parseJsoncText(patchText, "patch");

  const merged = mergeDeep(target, patch);
  const output = `${JSON.stringify(merged, null, 2)}\n`;
  Deno.writeTextFileSync(targetPath, output);
}

if (import.meta.main) {
  main(Deno.args);
}
