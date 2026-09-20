-- Plain Neovim: options and keymaps go here, the colorscheme comes from ze.

vim.g.mapleader = " "
vim.o.number = true
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.clipboard = "unnamedplus"

-- `ze theme set` writes ~/.config/ze/current/theme/nvim.lua:
--   { repo = "https://github.com/folke/tokyonight.nvim", colorscheme = "tokyonight-night", background = "dark" }
-- The colorscheme plugin is fetched with the built-in package manager (vim.pack, nvim >= 0.12).
-- The repo comes from the theme, so vim.pack keeps its confirmation prompt before cloning.
local function apply_ze_theme()
	local ok, theme = pcall(dofile, vim.fn.expand("~/.config/ze/current/theme/nvim.lua"))
	if not ok or type(theme) ~= "table" then
		return
	end

	if theme.repo and vim.pack then
		vim.pack.add({ theme.repo })
	end
	if theme.background then
		vim.o.background = theme.background
	end
	pcall(vim.cmd.colorscheme, theme.colorscheme)
end

apply_ze_theme()

-- ze sends SIGUSR1 to running instances after a theme switch
vim.api.nvim_create_autocmd("Signal", {
	pattern = "SIGUSR1",
	callback = apply_ze_theme,
})
