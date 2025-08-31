# Repository Guidelines

## Project Structure & Modules
- `karabiner/`: Deno TypeScript sources that generate Karabiner Elements config (`index.ts`, modes, leaders, utils). See `karabiner/README.md`.
- `raycast/`: Small shell utilities and exported `Raycast.rayconfig`.
- `mnt/`: Dotfiles and app configs (`nvim/`, `vscode/`, `yazi/`, etc.). Also `mnt/toki/` for project scaffolding templates and the `toki.sh` helper.
- Root: `provision.sh` for initial macOS setup, `README.md`, assets like `toki.webp`.

## Build, Test, and Development
- Karabiner dev: `cd karabiner && deno task dev` — watches TS and updates Karabiner config automatically.
- Provisioning: `./provision.sh` — bootstrap system packages and configs (macOS focused).
- Toki helper: `bash mnt/toki/toki.sh -h` — list scaffold targets (e.g., `pnpm`, `deno`, `go`, `vue`). Example: `bash mnt/toki/toki.sh pnpm ./playground`.
- Raycast scripts: run directly, e.g., `raycast/base64-encode.sh < file`.

## Coding Style & Naming
- TypeScript: prefer Biome or Prettier as used in each template; keep 2‑space indentation, organize imports, and avoid unused imports (Biome rule set in templates).
- Shell: POSIX/Bash with `set -eu`; use lowercase, hyphenated filenames.
- Lua (Neovim): follow existing module layout under `mnt/nvim/lua/` and keep concise, table‑driven configs.
- Keep filenames descriptive; match existing patterns (e.g., `leaders/semicolon.ts`, `modes/normal.ts`).

## Testing Guidelines
- No global test suite. For Deno code, use `deno test` where present. For templates (e.g., Jest), run tests inside the generated project (`pnpm test`).
- For Karabiner, validate changes by reloading and verifying key behaviors.
- Add minimal, focused tests alongside new Deno/TS modules when practical.

## Commit & Pull Requests
- Commit style: Conventional Commits in English or Japanese, e.g., `feat(karabiner): adjust Scoot hotkey`.
- Keep commits small and scoped; include rationale in the body when behavior changes.
- PRs: provide a clear description, affected areas (`karabiner/`, `mnt/nvim/`, etc.), steps to verify, and screenshots/GIFs for UX/keymap changes.
- Do not commit secrets or machine‑specific tokens; keep local overrides outside the repo.

## Security & Configuration Tips
- Review scripts before running with elevated permissions.
- Avoid committing private keys, API tokens, or OS‑specific identifiers. Store sensitive values externally.
