-- debug.lua
--
-- Unified debugging configuration for multiple languages.
-- Supports Python (with debugpy) and Scala (with nvim-metals).
-- Can be extended to other languages as well.

return {
  -- Main DAP plugin
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Python debugging support
    'mfussenegger/nvim-dap-python',

    -- Scala debugging and LSP support
    {
      'scalameta/nvim-metals',
      ft = { 'scala', 'sbt', 'java' },
    },

    -- Fidget for LSP progress notifications
    {
      'j-hui/fidget.nvim',
      opts = {},
    },
  },
  keys = {
    -- Unified keymaps for debugging (works for both Python and Scala)
    { '<leader>dc', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Debug: Toggle REPL' },
    { '<leader>dK', function() require('dap.ui.widgets').hover() end, desc = 'Debug: Hover Widget' },
    { '<leader>dt', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
    { '<leader>dso', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<leader>dsi', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<leader>dl', function() require('dap').run_last() end, desc = 'Debug: Run Last' },
    { '<leader>du', function() require('dapui').toggle() end, desc = 'Debug: Toggle DAP UI' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Set Conditional Breakpoint' },
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

    -- === PYTHON DEBUGGING SETUP ===
    local function setup_python_debugging()
      -- Function to find the best Python executable with debugpy
      local function find_python_with_debugpy()
        local python_candidates = {
          '~/.config/nvim/.venv/bin/python', -- nvim config venv
          vim.fn.exepath('python3'), -- system python3
          vim.fn.exepath('python'), -- system python
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
      
      -- Add Python debugging configurations
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

    -- === SCALA DEBUGGING SETUP ===
    local function setup_scala_debugging()
      -- Scala DAP configurations
      dap.configurations.scala = {
        {
          type = 'scala',
          request = 'launch',
          name = 'RunOrTest',
          metals = {
            runType = 'runOrTestFile',
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
    end

    -- === METALS (SCALA LSP) SETUP ===
    local function setup_metals()
      local metals_config = require('metals').bare_config()

      metals_config.settings = {
        showImplicitArguments = true,
        gradleScript = vim.fn.getcwd() .. '/gradlew',
        customProjectRoot = vim.fn.getcwd(),
        excludedPackages = { 'akka.actor.typed.javadsl', 'com.github.swagger.akka.javadsl' },
      }

      metals_config.init_options.statusBarProvider = 'off'
      -- metals_config.capabilities = require('cmp_nvim_lsp').default_capabilities()

      metals_config.on_attach = function(client, bufnr)
        require('metals').setup_dap()

        -- Helper function for buffer-local keymaps
        local function map(mode, lhs, rhs, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- LSP mappings (Scala-specific)
        map('n', 'gD', vim.lsp.buf.definition)
        map('n', 'K', vim.lsp.buf.hover)
        map('n', 'gi', vim.lsp.buf.implementation)
        map('n', 'gr', vim.lsp.buf.references)
        map('n', 'gds', vim.lsp.buf.document_symbol)
        map('n', 'gws', vim.lsp.buf.workspace_symbol)
        map('n', '<leader>cl', vim.lsp.codelens.run)
        map('n', '<leader>sh', vim.lsp.buf.signature_help)
        map('n', '<leader>rn', vim.lsp.buf.rename)
        map('n', '<leader>f', vim.lsp.buf.format)
        map('n', '<leader>ca', vim.lsp.buf.code_action)

        -- Scala worksheet support
        map('n', '<leader>ws', function()
          require('metals').hover_worksheet()
        end)

        -- Diagnostic mappings
        map('n', '<leader>aa', vim.diagnostic.setqflist) -- all workspace diagnostics
        map('n', '<leader>ae', function() -- all workspace errors
          vim.diagnostic.setqflist { severity = 'E' }
        end)
        map('n', '<leader>aw', function() -- all workspace warnings
          vim.diagnostic.setqflist { severity = 'W' }
        end)
        map('n', '<leader>d', vim.diagnostic.setloclist) -- buffer diagnostics only

        map('n', '[c', function()
          vim.diagnostic.goto_prev { wrap = false }
        end)
        map('n', ']c', function()
          vim.diagnostic.goto_next { wrap = false }
        end)
      end

      -- Auto-attach Metals for Scala files
      local nvim_metals_group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'scala', 'sbt', 'java' },
        callback = function()
          require('metals').initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
    end

    -- Initialize debugging support for all languages
    setup_python_debugging()
    setup_scala_debugging()
    setup_metals()
  end,
}