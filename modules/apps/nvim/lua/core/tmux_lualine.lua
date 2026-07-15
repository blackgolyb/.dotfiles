local M = {}

local config = {
	options = {
		component_separator = " ",
	},
	sections = {
		left = { "filename" },
		right = { "diagnostics" },
	},
}

local modes = {
	n = { name = "NORMAL", hl = "lualine_a_normal" },
	no = { name = "NORMAL", hl = "lualine_a_normal" },
	i = { name = "INSERT", hl = "lualine_a_insert" },
	ic = { name = "INSERT", hl = "lualine_a_insert" },
	v = { name = "VISUAL", hl = "lualine_a_visual" },
	V = { name = "V-LINE", hl = "lualine_a_visual" },
	["\22"] = { name = "V-BLOCK", hl = "lualine_a_visual" },
	R = { name = "REPLACE", hl = "lualine_a_replace" },
	c = { name = "COMMAND", hl = "lualine_a_command" },
	t = { name = "TERMINAL", hl = "lualine_a_terminal" },
}

local function escape_statusline(text)
	return tostring(text):gsub("%%", "%%%%")
end

local function hl(name, text)
	return "%#" .. name .. "#" .. escape_statusline(text) .. "%*"
end

local function get_hl(name)
	local ok, value = pcall(vim.api.nvim_get_hl, 0, { name = name })
	if ok then
		return value
	end

	return {}
end

local function update_derived_highlights()
	local info = get_hl("LualineModifiedCircle")

	vim.api.nvim_set_hl(0, "TmuxLualineNormal", {
		fg = "#909090",
		bg = "NONE",
		bold = true,
	})

	if info.fg then
		vim.api.nvim_set_hl(0, "TmuxLualineInfo", {
			fg = info.fg,
			bg = "NONE",
			bold = true,
		})
	end

	local error = get_hl("lualine_x_diagnostics_error_normal")
	if error.fg then
		vim.api.nvim_set_hl(0, "TmuxLualineDiagnosticError", {
			fg = error.fg,
			bg = "NONE",
			bold = error.bold,
		})
	end

	local warn = get_hl("lualine_x_diagnostics_warn_normal")
	if warn.fg then
		vim.api.nvim_set_hl(0, "TmuxLualineDiagnosticWarn", {
			fg = warn.fg,
			bg = "NONE",
			bold = warn.bold,
		})
	end
end

local function mode_component()
	local mode = modes[vim.api.nvim_get_mode().mode]
	if not mode then
		mode = { name = vim.api.nvim_get_mode().mode:upper(), hl = "lualine_a_normal" }
	end

	return hl(mode.hl, " " .. mode.name .. " ")
end

local function filename_component()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "[No Name]"
	end

	local parts = { hl("TmuxLualineNormal", " " .. filename) }

	if vim.bo.readonly then
		table.insert(parts, hl("TmuxLualineInfo", " "))
	end

	if vim.bo.modified then
		table.insert(parts, hl("TmuxLualineInfo", " ●"))
	end

	table.insert(parts, hl("TmuxLualineNormal", " "))
	return table.concat(parts, "")
end

local function diagnostics_component()
	local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
	local parts = {}

	if errors > 0 then
		table.insert(parts, hl("TmuxLualineDiagnosticError", "E:" .. errors))
	end

	if warnings > 0 then
		table.insert(parts, hl("TmuxLualineDiagnosticWarn", "W:" .. warnings))
	end

	return table.concat(parts, config.options.component_separator)
end

local components = {
	-- mode = mode_component,
	filename = filename_component,
	diagnostics = diagnostics_component,
}

local function render_section(section)
	local rendered = {}

	for _, component in ipairs(section) do
		local render = type(component) == "function" and component or components[component]
		if render then
			local value = render()
			if value and value ~= "" then
				table.insert(rendered, value)
			end
		end
	end

	return table.concat(rendered, config.options.component_separator)
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	update_derived_highlights()

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("TmuxLualineHighlights", { clear = true }),
		callback = vim.schedule_wrap(update_derived_highlights),
	})
end

function M.statusline()
	update_derived_highlights()

	local left = render_section(config.sections.left)
	local right = render_section(config.sections.right)

	if right == "" then
		return left
	end

	return left .. "%=" .. right
end

return M
