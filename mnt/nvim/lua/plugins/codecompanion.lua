return {
  "olimorris/codecompanion.nvim",
  cmd = {
    "CodeCompanion",
    "CodeCompanionChat",
    "CodeCompanionAction",
  },
  keys = {
    {
      "<Space>cp",
      ":CodeCompanion<CR>",
      mode = { "n", "v" },
      silent = true,
    },
    {
      "<Space>cc",
      ":CodeCompanionChat<CR>",
      mode = { "n", "v" },
      silent = true,
    },
    {
      "<Space>ca",
      ":CodeCompanionAction<CR>",
      mode = { "n", "v" },
      silent = true,
    },
    {
      "<Space>ct",
      function()
        require("codecompanion").prompt("trans_to_en")
      end,
      mode = { "v" },
      silent = true,
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim",
  },
  opts = function(_, opts)
    -- 環境に依存しない設定
    local base_opts = {
      opts = {
        language = "Japanese",
      },
      display = {
        chat = {
          auto_scroll = false,
        },
      },
      strategies = {
        chat = {
          roles = {
            llm = function(adapter)
              return " CodeCompanion (" .. adapter.formatted_name .. ")"
            end,
            user = " Me",
          },
          keymaps = {
            send = {
              modes = { n = "<C-CR>", i = "<C-CR>" }, -- Ctrl+Enter
            },
          },
        },
      },
      prompt_library = {
        ["Translate to English"] = {
          strategy = "inline",
          description = "選択したテキストを英語に翻訳します",
          opts = {
            short_name = "trans_to_en",
            modes = { "v" },
            adapter = {
              name = "copilot",
              model = "gpt-5",
            },
            -- INFO: コードを見るとstrategy = "inline" で対応してなさそう
            -- ignore_system_prompt = true,
          },
          prompts = {
            {
              role = "system",
              content = "あなたは優れた開発者であり、日本語と英語のプロ翻訳者でもあります。",
            },
            {
              role = "user",
              content = "<user_prompt>選択したコードドキュメントを英語に変換してください。</user_prompt>",
            },
          },
        },
        ["document translation"] = {
          strategy = "chat",
          opts = {
            use_promt = true,
            is_slash_cmd = true,
            auto_submit = true,
            short_name = "document translation",
          },
          prompts = {
            {
              role = "user",
              content = [[あなたは日本語と英語のプロの翻訳者であり、かつEnglish nativeとして経験豊富なスタッフエンジニアでもあります。以下の日本語で記載されたドキュメントを英語へと翻訳してください。コードのコメントやドキュメントに使われることを想定しています。]],
            },
          },
        },
        ["program name translation"] = {
          strategy = "chat",
          opts = {
            use_promt = true,
            is_slash_cmd = true,
            auto_submit = true,
            short_name = "program name translation",
          },
          prompts = {
            {
              role = "user",
              content = [[あなたは日本語と英語のプロの翻訳者であり、かつEnglish nativeとして経験豊富なスタッフエンジニアでもあります。以下の日本語で定義された変数名または関数名に対し、英語として適切な候補を挙げてください。明らかに推奨の候補があれば、それだけで構いません。]],
            },
          },
        },
        ["github issues translation"] = {
          strategy = "chat",
          opts = {
            use_promt = true,
            is_slash_cmd = true,
            auto_submit = true,
            short_name = "github issues translation",
          },
          prompts = {
            {
              role = "user",
              content = [[あなたは日本語と英語のプロの翻訳者であり、かつGitHubでEnglish nativeとしてIssuesのやりとりに慣れているエンジニアでもあります。引用句の英語メッセージに対して以下日本語の内容を返信する場合に適切な英語へと翻訳してください。引用句がない場合は気にしなくていいです。]],
            },
          },
        },
        ["github commit translation"] = {
          strategy = "chat",
          opts = {
            use_promt = true,
            is_slash_cmd = true,
            auto_submit = true,
            short_name = "github commit translation",
          },
          prompts = {
            {
              role = "user",
              content = [[あなたは日本語と英語のプロの翻訳者であり、かつGitHubでEnglish nativeとして開発に慣れているエンジニアでもあります。以下日本語のコミットメッセージを適切な英語へと翻訳してください。コミットメッセージにはConventional Commitsを利用しています。コミットメッセージの先頭は大文字で(例: feat: Add nice feature)]],
            },
          },
        },
        ["Normal commit"] = {
          strategy = "chat",
          description = "通常のコミットを行います",
          opts = {
            index = 10,
            is_default = true,
            is_slash_cmd = true,
            short_name = "normal commit",
            auto_submit = true,
          },
          prompts = {
            {
              role = "user",
              content = function()
                return string.format(
                  [[@cmd_runner
git diffで表示された内容からコミットメッセージを作成し、コミットしてください。コミットメッセージはheader(1行目)のみで日本語でお願いします。

```diff
%s
```
]],
                  vim.fn.system("git diff --no-ext-diff --staged")
                )
              end,
              opts = {
                contains_code = true,
              },
            },
          },
        },
      },
    }
    -- 環境ごとに切り分けたい設定
    local env_opts = require("envs.code-companion").opts

    -- デフォルト設定 -> 環境に依存しない設定 -> 環境に依存する設定 の順にマージ
    return vim.tbl_deep_extend("force", opts, base_opts, env_opts)
  end,
}
