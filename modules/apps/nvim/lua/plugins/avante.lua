_G.sidebar_on_open("avante", function()
  vim.cmd("AvanteChat")
end)

_G.sidebar_on_close("avante", function()
  pcall(function()
    local status_ok, avante = pcall(require, "avante")
    if not status_ok then return end

    local sidebar = avante.get()
    if sidebar and sidebar:is_open() then
      sidebar:close()
    end
  end)
end)

return {
  "yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  build = vim.fn.has("win32") ~= 0
  and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
  or "make",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    -- add any opts here
    -- this file can contain specific instructions for your project
    instructions_file = "AGENTS.md",
    -- for example
    provider = "copilot",
    auto_suggestions_provider = "copilot",
    providers = {},
    suggestion = {
      debounce = 75,
      throttle = 75,
    },
    behaviour = {
      auto_suggestions = true,
    },
  },
  keys = {
    { "<leader><leader>", function() _G.sidebar("avante") end, desc = "Toggle AI Chat", silent = true },
    { "<ESC>", function() _G.sidebar("none") end, desc = "Toggle AI Chat", silent = true },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-mini/mini.pick", -- for file_selector provider mini.pick
    "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    "stevearc/dressing.nvim", -- for input provider dressing
    "folke/snacks.nvim", -- for input provider snacks
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
