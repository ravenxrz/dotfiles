local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_BOOTSTRAP = fn.system {"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim",
                                  install_path}
    print "Installing packer close and reopen Neovim..."
    vim.cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
-- vim.cmd [[
--   augroup packer_user_config
--     autocmd!
--     autocmd BufWritePost plugins.lua source <afile> | PackerSync
--   augroup end
-- ]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
    return
end

-- Have packer use a popup window
packer.init {
    display = {
        -- open_fn = function()
        --   return require("packer.util").float { border = "rounded" }
        -- end,
    }
}

-- Install your plugins here
return packer.startup(function(use)
    -- My plugins here

    use { "wbthomason/packer.nvim"} -- Have packer manage itself
    use { "nvim-lua/plenary.nvim"} -- Useful lua functions used by lots of plugins
    use {"nvim-lua/popup.nvim"}
    use { "windwp/nvim-autopairs"} -- Autopairs, integrates with both cmp and treesitter
    use { "numToStr/Comment.nvim"}
    use { "JoosepAlviste/nvim-ts-context-commentstring"}
    use { "kyazdani42/nvim-web-devicons"}
    use { "nvim-tree/nvim-tree.lua", tag = "compat-nvim-0.7"}
    use { "akinsho/bufferline.nvim"}
    use { "moll/vim-bbye"}
    use { "nvim-lualine/lualine.nvim"}
    use { "akinsho/toggleterm.nvim"}
    use { "ahmedkhalf/project.nvim"}
    use { "lewis6991/impatient.nvim"}
    use { "goolord/alpha-nvim"}
    use { "folke/which-key.nvim"}

    -- Telescope
    use { "nvim-telescope/telescope.nvim"}
    use { "nvim-telescope/telescope-fzf-native.nvim", run = "make" }
    use "nvim-telescope/telescope-ui-select.nvim"
    use "nvim-telescope/telescope-live-grep-args.nvim"
    use "MattesGroeger/vim-bookmarks"
    use "tom-anders/telescope-vim-bookmarks.nvim"

    -- Treesittetr
    use { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate", tag = "v0.9.1"}
    use { "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter", requires = "nvim-treesitter/nvim-treesitter"} -- enhance texetobject selection
    use { "romgrk/nvim-treesitter-context" } -- show class/function at the top
    use {"andymass/vim-matchup"}
    use { "bfrg/vim-cpp-modern" }

    use { "neovim/nvim-lspconfig"} -- enable LSP
    use { "williamboman/mason.nvim"} -- simple to use language server installer
    use { "williamboman/mason-lspconfig.nvim"}
	use { "jose-elias-alvarez/null-ls.nvim"} -- for formatters and linters
    use { "RRethy/vim-illuminate"}

    use "ray-x/lsp_signature.nvim" -- show function signature when typing
    -- Editor enhance
    use "terrortylor/nvim-comment"  -- for comment
    use "preservim/nerdcommenter"
    use "Shatur/neovim-session-manager"
    use { "enddeadroyal/symbols-outline.nvim", branch = "bugfix/symbol-hover-misplacement" }

    -- cmp plugins
    use { "hrsh7th/nvim-cmp"} -- The completion plugin
    use { "hrsh7th/cmp-buffer"} -- buffer completions
    use { "hrsh7th/cmp-path"} -- path completions
    use { "hrsh7th/cmp-nvim-lsp"}
    use { "hrsh7th/cmp-nvim-lua"}
    use { "saadparwaiz1/cmp_luasnip"}

    use "ethanholz/nvim-lastplace" -- auto return back to the last modified positon when open a file
    -- use "BurntSushi/ripgrep" -- ripgrep
    use "nvim-pack/nvim-spectre" -- search and replace pane
    use "tpope/vim-repeat" --  . command enhance
    use "tpope/vim-surround" -- vim surround

    use { "phaazon/hop.nvim"}

    -- snippets
    use "L3MON4D3/LuaSnip" -- snippet engine
    use "rafamadriz/friendly-snippets" -- a bunch of snippets to use

    -- Git
    use { "lewis6991/gitsigns.nvim"}
    use 'sindrets/diffview.nvim'

    -- UI
    -- Colorschemes
    use "lunarvim/colorschemes" -- A bunch of colorschemes you can try out
    use "norcalli/nvim-colorizer.lua" -- show color
    use "folke/trouble.nvim"
    use {"j-hui/fidget.nvim", tag = "legacy"} -- show lsp progress
    use "sindrets/winshift.nvim" -- rerange window layout
    use 'AlexvZyl/nordic.nvim'
    -- use { "lukas-reineke/indent-blankline.nvim", tag = "v3.3.7" }
    -- litee family
    use "ldelossa/litee.nvim"
    use "ldelossa/litee-calltree.nvim"

    use {"cpea2506/one_monokai.nvim"}
    use { "loctvl842/monokai-pro.nvim" }

    -- tools
    use "voldikss/vim-translator"
    use "mtdl9/vim-log-highlighting"
    use "Pocco81/HighStr.nvim"
    use "vim-test/vim-test"
    -- use "ravenxrz/DoxygenToolkit.vim"
    use "Pocco81/auto-save.nvim"
    use "djoshea/vim-autoread"
    use { "VonHeikemen/fine-cmdline.nvim", requires = {{"MunifTanjim/nui.nvim"}} }

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if PACKER_BOOTSTRAP then
        require("packer").sync()
    end
end)
