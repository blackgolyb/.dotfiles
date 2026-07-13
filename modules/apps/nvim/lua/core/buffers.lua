-- Editable buffer manager, inspired by oil.nvim's buffer-as-interface model.
local ui = require("core.ui")

local M = {}

local ns = vim.api.nvim_create_namespace("BlackgolybBuffers")
local augroup = vim.api.nvim_create_augroup("BlackgolybBuffers", { clear = true })

local state = {
    winid = nil,
    bufnr = nil,
    float = false,
    source_winid = nil,
    source_bufnr = nil,
    items = {},
    original = {},
    manual_order = {},
    dirty = false,
}

local config = {
    order = "lastused",
    close_modified = "confirm",
    float = {
        width = 0.6,
        height = 0.45,
        border = ui.surface_border,
    },
}

local function valid_window(winid)
    return winid and vim.api.nvim_win_is_valid(winid)
end

local function display_name(name)
    return vim.fn.fnamemodify(name, ":~:.")
end

local function normalize_name(line)
    line = vim.trim(line)
    if line == "" then
        return nil
    end

    local expanded = vim.fn.expand(line)
    if expanded == "" then
        expanded = line
    end

    return vim.fn.fnamemodify(expanded, ":p")
end

local function get_icon(name)
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then
        return "", "Normal"
    end

    local icon, hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
    return icon or "", hl or "Normal"
end

local function get_items()
    local items = {}

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bufnr].buflisted then
            local name = vim.api.nvim_buf_get_name(bufnr)
            if name ~= "" then
                local info = vim.fn.getbufinfo(bufnr)[1] or {}
                table.insert(items, {
                    bufnr = bufnr,
                    name = name,
                    display = display_name(name),
                    lastused = info.lastused or 0,
                    loaded = vim.api.nvim_buf_is_loaded(bufnr),
                    modified = vim.bo[bufnr].modified,
                    readonly = vim.bo[bufnr].readonly,
                })
            end
        end
    end

    return items
end

local function apply_manual_order(items)
    if #state.manual_order == 0 then
        return items
    end

    local by_name = {}
    for _, item in ipairs(items) do
        by_name[item.name] = item
    end

    local ordered = {}
    local used = {}
    for _, name in ipairs(state.manual_order) do
        local item = by_name[name]
        if item then
            table.insert(ordered, item)
            used[name] = true
        end
    end

    for _, item in ipairs(items) do
        if not used[item.name] then
            table.insert(ordered, item)
        end
    end

    return ordered
end

local function apply_order(items)
    if config.order == "lastused" then
        table.sort(items, function(a, b)
            if a.lastused == b.lastused then
                return a.bufnr < b.bufnr
            end
            return a.lastused > b.lastused
        end)
        return items
    end

    if type(config.order) == "function" then
        local ok, ordered = pcall(config.order, vim.deepcopy(items))
        if ok and type(ordered) == "table" then
            return ordered
        end
        vim.notify("Buffer order function failed", vim.log.levels.WARN)
        return items
    end

    return apply_manual_order(items)
end

local function render_status()
    if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)

    local current_bufnr = state.source_bufnr or vim.api.nvim_get_current_buf()

    for index, item in ipairs(state.items) do
        local current = item.bufnr == current_bufnr and "▸" or "·"
        local modified = vim.bo[item.bufnr].modified and "●" or "○"
        local readonly = vim.bo[item.bufnr].readonly and "" or " "
        local icon, icon_hl = get_icon(item.name)

        vim.api.nvim_buf_set_extmark(state.bufnr, ns, index - 1, 0, {
            virt_text = {
                { current .. " ", "TelescopeSelectionCaret" },
                { modified .. " ", "DiagnosticWarn" },
                { readonly .. " ", "DiagnosticHint" },
                { icon .. " ", icon_hl },
            },
            virt_text_pos = "inline",
        })
    end
end

local function lines_from_items(items)
    local lines = {}
    for _, item in ipairs(items) do
        table.insert(lines, item.display)
    end
    return lines
end

local function set_manager_lines(lines)
    local old_undolevels = vim.bo[state.bufnr].undolevels

    vim.bo[state.bufnr].undolevels = -1
    vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
    vim.bo[state.bufnr].undolevels = old_undolevels
    vim.bo[state.bufnr].modified = false
end

local function make_buffer(float)
    local bufnr = vim.api.nvim_create_buf(false, false)
    local winid

    if float then
        local columns = vim.o.columns
        local lines = vim.o.lines
        local width = config.float.width <= 1 and math.floor(columns * config.float.width) or config.float.width
        local height = config.float.height <= 1 and math.floor(lines * config.float.height) or config.float.height

        winid = vim.api.nvim_open_win(bufnr, true, {
            relative = "editor",
            row = math.max(1, math.floor((lines - height) / 2)),
            col = math.max(1, math.floor((columns - width) / 2)),
            width = width,
            height = height,
            style = "minimal",
            border = config.float.border,
            title = " Buffers ",
            title_pos = "center",
        })
    else
        winid = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(winid, bufnr)
    end

    vim.wo[winid].cursorline = true
    vim.wo[winid].number = false
    vim.wo[winid].relativenumber = false
    vim.wo[winid].signcolumn = "no"
    vim.wo[winid].statuscolumn = " "

    vim.bo[bufnr].buftype = "acwrite"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].filetype = "buffer_manager"
    vim.bo[bufnr].swapfile = false
    vim.api.nvim_buf_set_name(bufnr, "buffer-manager")

    return bufnr, winid
end

local function item_lookup()
    local by_display = {}
    local by_name = {}

    for _, item in ipairs(state.original) do
        by_display[item.display] = by_display[item.display] or {}
        table.insert(by_display[item.display], item)
        by_name[item.name] = item
    end

    return by_display, by_name
end

local function items_from_lines(lines)
    local by_display, by_name = item_lookup()

    local items = {}
    local used = {}

    for _, line in ipairs(lines) do
        line = vim.trim(line)
        if line ~= "" then
            local item
            local candidates = by_display[line]
            if candidates then
                item = table.remove(candidates, 1)
            end

            if not item then
                local name = normalize_name(line)
                item = by_name[name]
                if not item and name then
                    vim.cmd("badd " .. vim.fn.fnameescape(name))
                    local bufnr = vim.fn.bufnr(name)
                    if bufnr ~= -1 then
                        item = {
                            bufnr = bufnr,
                            name = name,
                            display = display_name(name),
                            lastused = 0,
                            loaded = vim.api.nvim_buf_is_loaded(bufnr),
                            modified = false,
                            readonly = false,
                        }
                    end
                end
            end

            if item and not used[item.bufnr] then
                table.insert(items, item)
                used[item.bufnr] = true
            end
        end
    end

    return items, used
end

local function line_items()
    return items_from_lines(vim.api.nvim_buf_get_lines(state.bufnr, 0, -1, false))
end

local function delete_buffer(item)
    if not vim.api.nvim_buf_is_valid(item.bufnr) then
        return true
    end

    if vim.bo[item.bufnr].modified and config.close_modified ~= "force" then
        if config.close_modified ~= "confirm" then
            return false
        end

        local choice = vim.fn.confirm(
            "Close modified buffer?\n" .. item.display,
            "&Close\n&Keep",
            2
        )
        if choice ~= 1 then
            return false
        end
    end

    return pcall(vim.api.nvim_buf_delete, item.bufnr, {
        force = vim.bo[item.bufnr].modified or vim.bo[item.bufnr].buftype == "terminal",
    })
end

local function sync_menu(close_deleted)
    if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
        return
    end

    local items, kept = line_items()

    if close_deleted then
        for _, item in ipairs(state.original) do
            if not kept[item.bufnr] then
                delete_buffer(item)
            end
        end
    end

    state.manual_order = {}
    for _, item in ipairs(items) do
        table.insert(state.manual_order, item.name)
    end

    state.items = items
    state.original = vim.deepcopy(items)
    state.dirty = false
end

local function set_keymaps(bufnr)
    local opts = { buffer = bufnr, silent = true }

    vim.keymap.set("n", "<CR>", function()
        M.select()
    end, vim.tbl_extend("force", opts, { desc = "Open buffer" }))

    for _, key in ipairs({ "q", "<Esc>", "<leader>B" }) do
        vim.keymap.set("n", key, function()
            M.close()
        end, vim.tbl_extend("force", opts, { desc = "Close buffer manager" }))
    end

    vim.keymap.set("n", "J", ":move .+1<CR>==", vim.tbl_extend("force", opts, { desc = "Move buffer down" }))
    vim.keymap.set("n", "K", ":move .-2<CR>==", vim.tbl_extend("force", opts, { desc = "Move buffer up" }))
    vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "Move buffers down" }))
    vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "Move buffers up" }))

    vim.keymap.set("n", "<leader>r", function()
        M.refresh()
    end, vim.tbl_extend("force", opts, { desc = "Refresh buffers" }))

    vim.keymap.set("n", "<C-q>", function()
        M.to_quickfix()
    end, vim.tbl_extend("force", opts, { desc = "Buffers to quickfix" }))

    vim.keymap.set("x", "<C-q>", function()
        M.to_quickfix(vim.fn.line("v"), vim.fn.line("."))
    end, vim.tbl_extend("force", opts, { desc = "Selected buffers to quickfix" }))
end

local function set_autocmds(bufnr)
    vim.api.nvim_clear_autocmds({ group = augroup })

    vim.api.nvim_create_autocmd("OptionSet", {
        group = augroup,
        pattern = "modified",
        callback = function()
            if vim.api.nvim_get_current_buf() ~= bufnr then
                return
            end
            state.dirty = true
        end,
    })

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        group = augroup,
        buffer = bufnr,
        callback = function()
            sync_menu(true)
            vim.bo[bufnr].modified = false
            render_status()
        end,
    })
end

function M.open(opts)
    opts = opts or {}

    if valid_window(state.winid) then
        vim.api.nvim_set_current_win(state.winid)
        return
    end

    state.source_winid = vim.api.nvim_get_current_win()
    state.source_bufnr = vim.api.nvim_get_current_buf()
    state.float = opts.float == true

    state.items = apply_order(get_items())
    state.original = vim.deepcopy(state.items)
    state.dirty = false

    state.bufnr, state.winid = make_buffer(state.float)
    set_manager_lines(lines_from_items(state.items))

    set_keymaps(state.bufnr)
    set_autocmds(state.bufnr)
    render_status()
end

function M.close()
    if not valid_window(state.winid) then
        state.winid = nil
        state.bufnr = nil
        state.float = false
        state.source_winid = nil
        state.source_bufnr = nil
        return
    end

    sync_menu(true)

    local target = state.source_bufnr
    if not target or not vim.api.nvim_buf_is_valid(target) or not vim.bo[target].buflisted then
        target = nil
        for _, item in ipairs(state.items) do
            if vim.api.nvim_buf_is_valid(item.bufnr) and vim.bo[item.bufnr].buflisted then
                target = item.bufnr
                break
            end
        end
    end

    local manager_bufnr = state.bufnr
    local winid = state.winid
    local was_float = state.float

    if was_float then
        vim.api.nvim_win_close(winid, true)
        if valid_window(state.source_winid) then
            vim.api.nvim_set_current_win(state.source_winid)
        end
    elseif target then
        vim.api.nvim_win_set_buf(winid, target)
    else
        vim.cmd("enew")
    end

    if manager_bufnr and vim.api.nvim_buf_is_valid(manager_bufnr) then
        pcall(vim.api.nvim_buf_delete, manager_bufnr, { force = true })
    end

    state.winid = nil
    state.bufnr = nil
    state.float = false
    state.source_winid = nil
    state.source_bufnr = nil
end

function M.toggle(opts)
    if valid_window(state.winid) then
        M.close()
    else
        M.open(opts)
    end
end

function M.open_float()
    M.open({ float = true })
end

function M.toggle_float()
    M.toggle({ float = true })
end

function M.select(index)
    if not valid_window(state.winid) then
        return
    end

    sync_menu(false)
    index = index or vim.api.nvim_win_get_cursor(state.winid)[1]
    local item = state.items[index]
    if not item then
        return
    end

    local manager_bufnr = state.bufnr
    local winid = state.winid
    local source_winid = state.source_winid
    local was_float = state.float

    state.winid = nil
    state.bufnr = nil
    state.float = false
    state.source_winid = nil
    state.source_bufnr = nil

    if was_float then
        vim.api.nvim_win_close(winid, true)
        if valid_window(source_winid) then
            vim.api.nvim_set_current_win(source_winid)
            vim.api.nvim_win_set_buf(source_winid, item.bufnr)
        else
            vim.cmd("buffer " .. item.bufnr)
        end
    else
        vim.api.nvim_win_set_buf(winid, item.bufnr)
    end
    if manager_bufnr and vim.api.nvim_buf_is_valid(manager_bufnr) then
        pcall(vim.api.nvim_buf_delete, manager_bufnr, { force = true })
    end
end

function M.refresh()
    if not valid_window(state.winid) then
        return
    end

    state.items = apply_order(get_items())
    state.original = vim.deepcopy(state.items)
    set_manager_lines(lines_from_items(state.items))
    render_status()
end

function M.set_order(order)
    config.order = order
    M.refresh()
end

function M.to_quickfix(start_line, end_line)
    if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
        return
    end

    local line_count = vim.api.nvim_buf_line_count(state.bufnr)
    start_line = start_line or 1
    end_line = end_line or line_count

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    start_line = math.max(1, start_line)
    end_line = math.min(line_count, end_line)

    local lines = vim.api.nvim_buf_get_lines(state.bufnr, start_line - 1, end_line, false)
    local items = items_from_lines(lines)
    local entries = {}

    for _, item in ipairs(items) do
        table.insert(entries, {
            bufnr = item.bufnr,
            filename = item.name,
            lnum = 1,
            col = 1,
            text = item.display,
        })
    end

    if #entries == 0 then
        vim.notify("No buffers to send to quickfix", vim.log.levels.INFO)
        return
    end

    vim.fn.setqflist({}, "r", {
        title = "Buffers",
        items = entries,
    })
    vim.cmd("copen")
end

function M.close_unmodified_except_current()
    local current = vim.api.nvim_get_current_buf()
    local closed = 0

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if bufnr ~= current and vim.bo[bufnr].buflisted then
            local is_file = vim.bo[bufnr].buftype == ""
            if is_file and not vim.bo[bufnr].modified then
                local ok = pcall(vim.api.nvim_buf_delete, bufnr, {})
                if ok then
                    closed = closed + 1
                end
            end
        end
    end

    vim.notify("Closed " .. closed .. " unmodified buffer(s)", vim.log.levels.INFO)
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
