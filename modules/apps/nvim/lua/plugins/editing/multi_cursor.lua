-- Plugin: vim-visual-multi
-- URL: https://github.com/mg979/vim-visual-multi
-- Description: Adds multiple cursors and multi-selection editing.

local util = require("plugins.util")

-- pre
vim.g.VM_silent_exit = 1
vim.g.VM_maps = {
	["Find Under"] = "gl",
	["Find Prev"] = "gL",
	["Skip Region"] = "g>",
	["Remove Region"] = "g<",
	["Add Cursor Down"] = "gj",
	["Add Cursor Up"] = "gk",
	["Select Operator"] = "",
	["Switch Mode"] = "v",
	["Exit"] = "<C-c>",
}

-- install
vim.pack.add({
	{ src = util.gh("mg979/vim-visual-multi"), version = "master" },
})

-- setup
local function in_vm()
	return vim.fn.exists("b:visual_multi") == 1
end

local function in_vm_extend_mode()
	local vm = vim.g.Vm
	return type(vm) == "table" and vm.extend_mode == 1
end

local function feed(keys, mode)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), mode, false)
end

local function feed_and_nohlsearch(keys)
	feed(keys, "m")
	vim.schedule(function()
		vim.cmd.nohlsearch()
	end)
end

-- Additional Keymaps
vim.keymap.set("x", "gI", "<Plug>(VM-Visual-Cursors)", { remap = true })
vim.keymap.set("x", "gl", "<Plug>(VM-Find-Subword-Under)", { remap = true })
vim.keymap.set("n", "ga", function()
	vim.cmd("call vm#commands#find_all(0, 1)")
	vim.cmd.nohlsearch()
end, { silent = true })
vim.keymap.set("x", "ga", function()
	feed_and_nohlsearch("<Plug>(VM-Visual-All)")
end, { silent = true })

local group = vim.api.nvim_create_augroup("visual_multi_custom_esc", { clear = true })

-- Drop highlights via "noh" after go to a Insert mode
vim.api.nvim_create_autocmd("ModeChanged", {
	group = group,
	pattern = "*:i*",
	callback = function()
		if vim.fn.exists("b:visual_multi") ~= 1 then
			return
		end

		vim.schedule(function()
			vim.v.hlsearch = 0
		end)
	end,
})

-- Add support for copy/paste after: x, X <Del> in VM
vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "visual_multi_mappings",
	callback = function(args)
		local function delete_key(key)
			if in_vm_extend_mode() then
				vim.cmd("call b:VM_Selection.Edit.delete(1, v:register, v:count1, 1)")
			else
				vim.cmd(
					("call b:VM_Selection.Edit.run_normal('%s', {'count': v:count1, 'recursive': 0, 'store': v:register, 'vimreg': 1})"):format(
						key
					)
				)
			end
		end

		vim.keymap.set("n", "x", function()
			delete_key("x")
		end, { buffer = args.buf, silent = true })

		vim.keymap.set("n", "X", function()
			delete_key("X")
		end, { buffer = args.buf, silent = true })

		vim.keymap.set("n", "<Del>", function()
			delete_key("x")
		end, { buffer = args.buf, silent = true })

		vim.keymap.set("n", "s", function()
			if in_vm_extend_mode() then
				vim.cmd("call b:VM_Selection.Edit.delete(1, v:register, v:count1, 1)")
			else
				local count = vim.v.count1 > 1 and vim.v.count1 or ""
				vim.cmd(
					("call b:VM_Selection.Edit.run_normal('d%sl', {'recursive': 0, 'store': v:register, 'vimreg': 1})"):format(
						count
					)
				)
			end

			vim.cmd("call b:VM_Selection.Insert.key('i')")
		end, { buffer = args.buf, silent = true })
	end,
})

-- Add more vim behaviour for <Esc> in VM
vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "visual_multi_start",
	callback = function()
		vim.keymap.set("n", "<Esc>", function()
			vim.cmd.nohlsearch()

			if not in_vm() then
				pcall(vim.keymap.del, "n", "<Esc>", { buffer = true })
				feed("<Esc>", "m")
			elseif in_vm_extend_mode() then
				vim.cmd("call b:VM_Selection.Global.change_mode(1)")
			else
				feed("<Plug>(VM-Exit)", "m")
			end
		end, { buffer = true, nowait = true, silent = true })
	end,
})

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "visual_multi_exit",
	callback = function(args)
		pcall(vim.keymap.del, "n", "<Esc>", { buffer = args.buf })
	end,
})
