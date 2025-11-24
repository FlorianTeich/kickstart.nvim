return {
  "Vigemus/iron.nvim",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    local common = require("iron.fts.common")

    iron.setup({
      config = {
        scratch_repl = true,
        -- How the repl window will be displayed
        repl_open_cmd = view.bottom(40),
        -- Choose your preferred REPL for each language:
        repl_definition = {
          sh = {
            command = {"zsh"}
          },
          python = {
            command = {"python3"},
            format = common.bracketed_paste_python,
          },
        },
      },

      keymaps = {
        send_motion = "<leader>rs",
        visual_send = "<leader>rs",
        send_file = "<leader>rf",
        send_line = "<leader>rl",
        send_mark = "<leader>rm",
        mark_motion = "<leader>rm",
        mark_visual = "<leader>rm",
        remove_mark = "<leader>rd",
        cr = "<leader>r<cr>",
        interrupt = "<leader>r<space>",
        exit = "<leader>rq",
        clear = "<leader>rc",
      },

      highlight = { italic = true },
      ignore_blank_lines = true,
    })

    -- Optional: automatically open the REPL on first send
    vim.keymap.set("n", "<leader>ro", function()
      local ft = vim.bo.filetype
      require("iron.core").repl_for(ft)
      require("iron.core").focus_on(ft)
    end)
  end,
}
