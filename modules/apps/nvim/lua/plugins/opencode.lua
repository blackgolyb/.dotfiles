return {
    "nickjvandyke/opencode.nvim",
    version = "*", -- Latest stable release
    config = function()
        local M = { win = nil, buf = nil }

        function M.open()
            if M.win and vim.api.nvim_win_is_valid(M.win) then
                vim.api.nvim_set_current_win(M.win)
                vim.cmd("startinsert")
                return
            end
            vim.cmd("botright vsplit")
            M.win = vim.api.nvim_get_current_win()
            vim.cmd("vertical resize 60")
            if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
                vim.api.nvim_win_set_buf(M.win, M.buf)
            else
                vim.cmd("terminal opencode --port")
                M.buf = vim.api.nvim_get_current_buf()
                vim.bo[M.buf].buftype = "terminal"
                vim.bo[M.buf].bufhidden = "hide"
            end
            vim.wo.number = false
            vim.wo.relativenumber = false
            vim.wo.signcolumn = "no"
            vim.keymap.set("n", "<Esc>", function()
                if M.win and vim.api.nvim_win_is_valid(M.win) then
                    vim.api.nvim_win_close(M.win, true)
                    M.win = nil
                end
            end, { buffer = M.buf, silent = true })
            vim.keymap.set({"n", "t"}, "<C-e>", function() _G.sidebar("ai-prompt") end,
                { desc = "Edit prompt", buffer = M.buf, silent = true })
            vim.keymap.set("n", "<leader>of", function() M.toggle_fullscreen() end,
                { desc = "Toggle OpenCode fullscreen sidebar", buffer = M.buf, silent = true })
            vim.keymap.set({"n", "t"}, "<C-u>", function() require("opencode").command("session.half.page.up") end,
                { desc = "Scroll OpenCode up", buffer = M.buf, silent = true })
            vim.keymap.set({"n", "t"}, "<C-d>", function() require("opencode").command("session.half.page.down") end,
                { desc = "Scroll OpenCode down", buffer = M.buf, silent = true })
            vim.keymap.set("n", "G", function() require("opencode").command("session.last") end,
                { desc = "Go to bottom", buffer = M.buf, silent = true })
            vim.keymap.set("n", "{", function() require("opencode").command("session.page.up") end,
                { desc = "Prev message", buffer = M.buf, silent = true })
            vim.keymap.set("n", "}", function() require("opencode").command("session.page.down") end,
                { desc = "Next message", buffer = M.buf, silent = true })
            vim.cmd("startinsert")
            vim.defer_fn(function()
                if M.win and vim.api.nvim_win_is_valid(M.win) then
                    vim.cmd("startinsert")
                end
            end, 200)
        end

        function M.close()
            if M.win and vim.api.nvim_win_is_valid(M.win) then
                vim.api.nvim_win_close(M.win, true)
                M.win = nil
            end
        end

        _G.sidebar_on_open("ai", M.open)
        _G.sidebar_on_close("ai", M.close)

        local prompt = { buf = nil }

        function M.open_prompt()
            local old = vim.fn.bufnr("opencode-prompt")
            if old ~= -1 then
                vim.api.nvim_buf_delete(old, { force = true })
            end
            vim.cmd("botright vsplit")
            local win = vim.api.nvim_get_current_win()
            vim.cmd("vertical resize 60")
            prompt.buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_win_set_buf(win, prompt.buf)
            vim.bo[prompt.buf].buftype = "nofile"
            vim.bo[prompt.buf].bufhidden = "wipe"
            vim.bo[prompt.buf].filetype = "opencode_prompt"
            vim.api.nvim_buf_set_name(prompt.buf, "opencode-prompt")
            vim.wo.number = false
            vim.wo.relativenumber = false
            vim.wo.signcolumn = "no"
            vim.wo.wrap = true
            vim.api.nvim_buf_set_lines(prompt.buf, 0, -1, false, {})
            vim.cmd("normal! gg")
            vim.cmd("startinsert")
            vim.defer_fn(function()
                if vim.api.nvim_buf_is_valid(prompt.buf) then
                    vim.cmd("startinsert")
                end
            end, 100)
            vim.api.nvim_create_autocmd("WinClosed", {
                pattern = tostring(win),
                once = true,
                callback = function()
                    local b = prompt.buf
                    local content = ""
                    if b and vim.api.nvim_buf_is_valid(b) then
                        local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
                        content = table.concat(lines, "\n")
                    end
                    prompt.buf = nil
                    vim.schedule(function()
                        M.send_to_opencode(content)
                        _G.sidebar("ai")
                    end)
                end,
            })
        end

        function M.send_to_opencode(content)
            if not content:match("%S") then
                return
            end
            require("opencode.server.discovery").get():next(function(server)
                server:tui_execute_command("prompt.clear"):next(function()
                    server:tui_append_prompt(content .. " ")
                end)
            end)
        end

        function M.close_prompt()
            local buf = prompt.buf
            prompt.buf = nil
            if not buf or not vim.api.nvim_buf_is_valid(buf) then
                return
            end
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local content = table.concat(lines, "\n")
            local win = vim.fn.bufwinid(buf)
            if win ~= -1 and vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
            M.send_to_opencode(content)
        end

        _G.sidebar_on_open("ai-prompt", M.open_prompt)
        _G.sidebar_on_close("ai-prompt", M.close_prompt)

        ---@type opencode.Opts
        vim.g.opencode_opts = {
            server = {
                start = M.open,
            },
            events = {
                permissions = {
                    enabled = false,
                    edits = {
                        enabled = false,
                    },
                },
            },
        }

        vim.o.autoread = true

        function M.open_fullscreen()
            if M.win and vim.api.nvim_win_is_valid(M.win) then
                vim.api.nvim_set_current_win(M.win)
                vim.cmd("startinsert")
                return
            end
            if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
                vim.cmd("terminal opencode --port")
                M.buf = vim.api.nvim_get_current_buf()
                vim.bo[M.buf].buftype = "terminal"
                vim.bo[M.buf].bufhidden = "hide"
            end
            local width = vim.o.columns - 4
            local height = vim.o.lines - 4
            M.win = vim.api.nvim_open_win(M.buf, true, {
                relative = "editor",
                width = width,
                height = height,
                row = 1,
                col = 1,
                style = "minimal",
                border = "rounded",
            })
            vim.wo.number = false
            vim.wo.relativenumber = false
            vim.wo.signcolumn = "no"
            vim.cmd("startinsert")
        end

        function M.toggle_fullscreen()
            if M.win and vim.api.nvim_win_is_valid(M.win) then
                local width = vim.api.nvim_win_get_width(M.win)
                if width == 60 then
                    vim.cmd("wincmd |")
                else
                    vim.cmd("vertical resize 60")
                end
                vim.cmd("startinsert")
            else
                M.open()
                vim.cmd("wincmd |")
                vim.cmd("startinsert")
            end
        end

        vim.keymap.set({ "n", "x" }, "<leader><leader>", function() _G.sidebar("ai") end,
            { desc = "Toggle OpenCode sidebar", silent = true })
        vim.keymap.set({ "n", "x" }, "<leader>os", function() require("opencode").ask("@this: ") end,
            { desc = "Ask OpenCode…" })
        vim.keymap.set({ "n", "x" }, "<leader>op", function() require("opencode").select() end,
            { desc = "Select OpenCode…" })
        vim.keymap.set({ "n", "x" }, "<leader>oi", function() _G.sidebar("ai-prompt") end,
            { desc = "Edit prompt in buffer" })

        vim.keymap.set("n", "<leader>of", function() M.toggle_fullscreen() end,
            { desc = "Toggle OpenCode fullscreen sidebar" })

        vim.keymap.set({ "n", "x" }, "<leader>oa", function() return require("opencode").operator("@this ") end,
            { desc = "Append range to OpenCode", expr = true })

        vim.keymap.set({ "n", "t" }, "<C-q>", function() _G.sidebar_close() end,
            { desc = "Close current sidebar", silent = true })
    end,
}
