return {
  {
    'dmtrKovalenko/fff.nvim',
    build = function()
      -- this will download prebuild binary or try to use existing rustup toolchain to build from source
      -- (if you are using lazy you can use gb for rebuilding a plugin if needed)
      require("fff.download").download_or_build_binary()
    end,
    -- if you are using nixos
    -- build = "nix run .#release",
    opts = { -- (optional)
      debug = {
        enabled = true,     -- we expect your collaboration at least during the beta
        show_scores = false, -- to help us optimize the scoring system, feel free to share your scores!
      },
      prompt = '  ',
      title = 'Files',
      preview = {
        enabled = false,
      },
      layout = {
        border = 'single',
        title_pos = 'center',
        prompt_position = 'top',
        height = 0.6,
        width = 0.4,
      },
      hl = {
        border = 'FFFBorder',
        normal = 'FFFNormal',
        prompt = 'FFFPrompt',
        title = 'FFFTitle',
        cursor = 'FFFCursor',
      },
    },
    -- No need to lazy-load with lazy.nvim.
    -- This plugin initializes itself lazily.
    lazy = false,
    keys = {
      {
        "<leader>f", -- try it if you didn't it is a banger keybinding for a picker
        function() require('fff').find_files() end,
        desc = 'Fuzzy Find Files',
      }
    },
    config = function(_, opts)
      local fff_layout = require('fff.layout')

      if not fff_layout._title_pos_patched then
        local compute = fff_layout.compute

        fff_layout.compute = function(config, ...)
          local result = compute(config, ...)
          local title_pos = config.layout and config.layout.title_pos

          if title_pos and result.win_configs then
            for _, win in ipairs({ result.win_configs.list, result.win_configs.input }) do
              if win and win.title then
                win.title_pos = title_pos
              end
            end
          end

          return result
        end

        fff_layout._title_pos_patched = true
      end

      require("fff").setup(opts)

      vim.keymap.set("i", "<C-x><C-f>", function()
        require("fff").find_files({
          on_submit = function(item, ctx)
            local path = ctx.relative_path
            vim.api.nvim_feedkeys("a" .. path, "n", false)
          end,
        })
      end, { desc = "Insert file path via fff" })
    end,
  },
}
