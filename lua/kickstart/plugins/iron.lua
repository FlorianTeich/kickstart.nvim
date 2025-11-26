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
        repl_open_cmd = "botright 12 new | setlocal buftype=nofile",
        -- Send selections to the DAP repl if an nvim-dap session is running.
        dap_integration = true,
        -- Choose your preferred REPL for each language:
        repl_definition = {
          sh = {
            command = {"zsh"}
          },
          python = {
            command = {"python3"},
            format = common.bracketed_paste_python,
            block_dividers = { "# %%", "#%%" },
            env = {PYTHON_BASIC_REPL = "1"} 
          },
        },
      },

      keymaps = {
        toggle_repl = "<space>rr", -- toggles the repl open and closed.
        -- If repl_open_command is a table as above, then the following keymaps are
        -- available
        -- toggle_repl_with_cmd_1 = "<space>rv",
        -- toggle_repl_with_cmd_2 = "<space>rh",
        restart_repl = "<space>rR", -- calls `IronRestart` to restart the repl
        send_motion = "<space>sc",
        visual_send = "<space>sc",
        send_file = "<space>sf",
        send_line = "<space>sl",
        send_paragraph = "<space>sp",
        send_until_cursor = "<space>su",
        send_mark = "<space>sm",
        send_code_block = "<space>sb",
        send_code_block_and_move = "<space>sn",
        mark_motion = "<space>mc",
        mark_visual = "<space>mc",
        remove_mark = "<space>md",
        cr = "<space>s<cr>",
        interrupt = "<space>s<space>",
        exit = "<space>sq",
        clear = "<space>cl",
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
