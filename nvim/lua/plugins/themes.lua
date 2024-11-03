return {
	{
		"Mofiqul/dracula.nvim",
		priority = 1000,
	},
	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		priority = 1000,
	},
	{
		"NLKNguyen/papercolor-theme",
		lazy = fals,
		priority = 1000,
	},
	{
		"maxmx03/solarized.nvim",
		lazy = false,
		priority = 1000,
	},
	-- {
	--   "sainnhe/sonokai",
	--   priority = 999,
	-- },
	-- {
	--   "eldritch-theme/eldritch.nvim",
	--   lazy = false,
	--   priority = 999,
	--   opts = {},
	-- },
	{
		"miikanissi/modus-themes.nvim",
		priority = 1000,
		config = function()
			require("modus-themes").setup({
				-- Theme comes in two styles `modus_operandi` and `modus_vivendi`
				-- `auto` will automatically set style based on background set with vim.o.background
				style = "modus_operandi",
				variant = "tinted", -- Theme comes in four variants `default`, `tinted`, `deuteranopia`, and `tritanopia`
				transparent = false, -- Transparent background (as supported by the terminal)
				dim_inactive = false, -- "non-current" windows are dimmed
				styles = {
					-- Style to be applied to different syntax groups
					-- Value is any valid attr-list value for `:help nvim_set_hl`
					comments = { italic = true },
					keywords = { italic = true },
					functions = {},
					variables = {},
				},
			})
		end,
	},
}
