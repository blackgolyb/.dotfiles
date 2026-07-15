local M = {}

function M.setup()
	if not vim.pack then
		error("vim.pack is not available in this Neovim version")
	end

	vim.api.nvim_create_user_command("PackUpdate", function()
		vim.pack.update()
	end, { desc = "Update installed plugins" })

	vim.api.nvim_create_user_command("PackDelete", function(opts)
		vim.pack.del({ opts.args })
	end, { nargs = 1, desc = "Delete managed plugin" })

	vim.api.nvim_create_user_command("PackHealth", function()
		vim.cmd.checkhealth()
	end, { desc = "Run Neovim health checks" })
end

return M
