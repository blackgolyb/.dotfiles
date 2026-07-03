local pane = vim.env.TMUX_PANE
local tmux = vim.env.TMUX

if not pane or pane == "" or not tmux or tmux == "" then
    return
end

local modes = {
    n = "NORMAL",
    no = "OP-PENDING",
    nov = "OP-PENDING",
    noV = "OP-PENDING",
    ["no\22"] = "OP-PENDING",
    niI = "NORMAL",
    niR = "NORMAL",
    niV = "NORMAL",
    nt = "NORMAL",
    v = "VISUAL",
    vs = "VISUAL",
    V = "V-LINE",
    Vs = "V-LINE",
    ["\22"] = "V-BLOCK",
    ["\22s"] = "V-BLOCK",
    s = "SELECT",
    S = "S-LINE",
    ["\19"] = "S-BLOCK",
    i = "INSERT",
    ic = "INSERT",
    ix = "INSERT",
    R = "REPLACE",
    Rc = "REPLACE",
    Rx = "REPLACE",
    Rv = "V-REPLACE",
    Rvc = "V-REPLACE",
    Rvx = "V-REPLACE",
    c = "COMMAND",
    cv = "EX",
    ce = "EX",
    r = "PROMPT",
    rm = "MORE",
    ["r?"] = "CONFIRM",
    ["!"] = "SHELL",
    t = "TERMINAL",
}

local function diagnostic_count(severity)
    return #vim.diagnostic.get(0, { severity = severity })
end

local function diagnostics_summary()
    local errors = diagnostic_count(vim.diagnostic.severity.ERROR)
    local warnings = diagnostic_count(vim.diagnostic.severity.WARN)
    local parts = {}

    if errors > 0 then
        table.insert(parts, "E" .. errors)
    end

    if warnings > 0 then
        table.insert(parts, "W" .. warnings)
    end

    return table.concat(parts, " ")
end

local function status_text()
    local mode = modes[vim.api.nvim_get_mode().mode] or vim.api.nvim_get_mode().mode:upper()
    local file = vim.fn.expand("%:t")

    if file == "" then
        file = "[No Name]"
    end

    if vim.bo.modified then
        file = file .. " [+]"
    end

    local diagnostics = diagnostics_summary()
    if diagnostics ~= "" then
        return table.concat({ mode, file, diagnostics }, " ")
    end

    return table.concat({ mode, file }, " ")
end

local function write_status()
    vim.fn.jobstart({ "tmux", "set-option", "@nvim_status", status_text() }, { detach = true })
    vim.fn.jobstart({ "tmux", "refresh-client", "-S" }, { detach = true })
end

local function clear_status()
    vim.fn.jobstart({ "tmux", "set-option", "-u", "@nvim_status" }, { detach = true })
    vim.fn.jobstart({ "tmux", "refresh-client", "-S" }, { detach = true })
end

local function clear_status_blocking()
    vim.fn.system({ "tmux", "set-option", "-u", "@nvim_status" })
    vim.fn.system({ "tmux", "refresh-client", "-S" })
end

local group = vim.api.nvim_create_augroup("TmuxStatus", { clear = true })

vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufFilePost",
    "BufModifiedSet",
    "BufWritePost",
    "DiagnosticChanged",
    "FocusGained",
    "ModeChanged",
}, {
    group = group,
    callback = write_status,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = clear_status_blocking,
})

vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = clear_status,
})

write_status()
