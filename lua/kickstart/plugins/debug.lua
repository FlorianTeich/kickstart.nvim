return {
  -- Main DAP plugin
  'mfussenegger/nvim-dap',
  dependencies = {
    -- DAP UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Python debugging support
    'mfussenegger/nvim-dap-python',
  },
  keys = {
    -- Unified keymaps for debugging (works for both Python & Scala)
    { '<leader>dc', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Debug: Toggle REPL' },
    { '<leader>dK', function() require('dap.ui.widgets').hover() end, desc = 'Debug: Hover Widget' },
    { '<leader>dt', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
    { '<leader>dso', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<leader>dsi', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<leader>dl', function() require('dap').run_last() end, desc = 'Debug: Run Last' },
    { '<leader>du', function() require('dapui').toggle() end, desc = 'Debug: Toggle DAP UI' },
    { '<leader>dB', function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Conditional Breakpoint',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Mason DAP setup for automatic debugger installation
    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'debugpy', -- Python debugger
      },
    }

    -- DAP UI setup
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Auto-open/close DAP UI
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    ---------------------------------------------------------------------------
    -- PYTHON DEBUGGING SETUP
    ---------------------------------------------------------------------------
    local function setup_python_debugging()
      -- Function to find the best Python executable with debugpy
      local function find_python_with_debugpy()
        local python_candidates = {
          '~/.config/nvim/.venv/bin/python', -- nvim config venv
          vim.fn.exepath('python3'),        -- system python3
          vim.fn.exepath('python'),         -- system python
        }

        for _, python_path in ipairs(python_candidates) do
          if python_path and python_path ~= '' and vim.fn.executable(python_path) == 1 then
            -- Test if this python has debugpy
            local handle = io.popen(python_path .. ' -c "import debugpy; print(debugpy.__file__)" 2>/dev/null')
            if handle then
              local result = handle:read('*a')
              handle:close()
              if result and result:match('debugpy') then
                return python_path
              end
            end
          end
        end

        -- Fallback to the nvim config venv
        return '~/.config/nvim/.venv/bin/python'
      end

      require('dap-python').setup(find_python_with_debugpy())

      -- Add Python debugging configuration
      dap.configurations.python = dap.configurations.python or {}
      table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
          local cwd = vim.fn.getcwd()
          if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
            return cwd .. '/venv/bin/python'
          elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
            return cwd .. '/.venv/bin/python'
          else
            return '/usr/bin/python'
          end
        end,
      })
    end

    ---------------------------------------------------------------------------
    -- SCALA DEBUGGING SETUP (from your Metals config)
    ---------------------------------------------------------------------------
    dap.configurations.scala = {
      {
        type = 'scala',
        request = 'launch',
        name = 'RunOrTest',
        metals = {
          runType = 'runOrTestFile',
          -- args = { "firstArg", "secondArg", "thirdArg" }, -- example
        },
      },
      {
        type = 'scala',
        request = 'launch',
        name = 'Test Target',
        metals = {
          runType = 'testTarget',
        },
      },
    }

    -- Initialize debugging support
    setup_python_debugging()
  end,
}
