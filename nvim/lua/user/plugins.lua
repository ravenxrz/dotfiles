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

    use { "wbthomason/packer.nvim", commit = "6afb67460283f0e990d35d229fd38fdc04063e0a" } -- Have packer manage itself
    use { "nvim-lua/plenary.nvim", commit = "4b7e52044bbb84242158d977a50c4cbcd85070c7" } -- Useful lua functions used by lots of plugins
    use {"nvim-lua/popup.nvim"}
    use { "windwp/nvim-autopairs", commit = "4fc96c8f3df89b6d23e5092d31c866c53a346347" } -- Autopairs, integrates with both cmp and treesitter
    use { "numToStr/Comment.nvim", commit = "97a188a98b5a3a6f9b1b850799ac078faa17ab67" }
    use { "JoosepAlviste/nvim-ts-context-commentstring", commit = "4d3a68c41a53add8804f471fcc49bb398fe8de08" }
    use { "kyazdani42/nvim-web-devicons", commit = "563f3635c2d8a7be7933b9e547f7c178ba0d4352" }
    use { "nvim-tree/nvim-tree.lua", commit = "7282f7de8aedf861fe0162a559fc2b214383c51c" }
    use { "akinsho/bufferline.nvim", commit = "83bf4dc7bff642e145c8b4547aa596803a8b4dc4" }
    use { "moll/vim-bbye", commit = "25ef93ac5a87526111f43e5110675032dbcacf56" }
    use { "nvim-lualine/lualine.nvim", commit = "a52f078026b27694d2290e34efa61a6e4a690621" }
    use { "akinsho/toggleterm.nvim", commit = "2a787c426ef00cb3488c11b14f5dcf892bbd0bda" }
    use { "ahmedkhalf/project.nvim", commit = "628de7e433dd503e782831fe150bb750e56e55d6" }
    use { "lewis6991/impatient.nvim", commit = "b842e16ecc1a700f62adb9802f8355b99b52a5a6" }
    use { "goolord/alpha-nvim", commit = "0bb6fc0646bcd1cdb4639737a1cee8d6e08bcc31" }
    use { "folke/which-key.nvim", commit = "16ed12a8493628c377606da2ebac50d80736ed37" }

    -- Telescope
    use { "nvim-telescope/telescope.nvim", tag = "0.1.1" }
    use { "nvim-telescope/telescope-fzf-native.nvim", run = "make" }
    use "nvim-telescope/telescope-ui-select.nvim"
    use "nvim-telescope/telescope-live-grep-args.nvim"
    use "MattesGroeger/vim-bookmarks"
    use "tom-anders/telescope-vim-bookmarks.nvim"

    -- Treesittetr
    use { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate", commit = "4cccb6f494eb255b32a290d37c35ca12584c74d0" }
    use { "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter", requires = "nvim-treesitter/nvim-treesitter", commit = "c81382328ad47c154261d1528d7c921acad5eae5"} -- enhance texetobject selection
    use { "romgrk/nvim-treesitter-context", tag = "compat/0.7" } -- show class/function at the top
    use {"andymass/vim-matchup", tag = "v0.7.2"}

    use { "neovim/nvim-lspconfig", commit = "f11fdff7e8b5b415e5ef1837bdcdd37ea6764dda" } -- enable LSP
    use { "williamboman/mason.nvim", commit = "c2002d7a6b5a72ba02388548cfaf420b864fbc12"} -- simple to use language server installer
    use { "williamboman/mason-lspconfig.nvim", commit = "0051870dd728f4988110a1b2d47f4a4510213e31" }
	use { "jose-elias-alvarez/null-ls.nvim", commit = "c0c19f32b614b3921e17886c541c13a72748d450" } -- for formatters and linters
    use { "RRethy/vim-illuminate", commit = "a2e8476af3f3e993bb0d6477438aad3096512e42" }


    use "ray-x/lsp_signature.nvim" -- show function signature when typing
    -- Editor enhance
    use "terrortylor/nvim-comment"  -- for comment
    use "preservim/nerdcommenter"
    use "Shatur/neovim-session-manager"
    use 'Davonter/codeium.vim'      -- for completion by AI
    use { "enddeadroyal/symbols-outline.nvim", branch = "bugfix/symbol-hover-misplacement" }

    -- cmp plugins
    use { "hrsh7th/nvim-cmp", commit = "b0dff0ec4f2748626aae13f011d1a47071fe9abc" } -- The completion plugin
    use { "hrsh7th/cmp-buffer", commit = "3022dbc9166796b644a841a02de8dd1cc1d311fa" } -- buffer completions
    use { "hrsh7th/cmp-path", commit = "447c87cdd6e6d6a1d2488b1d43108bfa217f56e1" } -- path completions
    use { "hrsh7th/cmp-nvim-lsp", commit = "3cf38d9c957e95c397b66f91967758b31be4abe6" }
    use { "hrsh7th/cmp-nvim-lua", commit = "d276254e7198ab7d00f117e88e223b4bd8c02d21" }
    use { "saadparwaiz1/cmp_luasnip", commit = "a9de941bcbda508d0a45d28ae366bb3f08db2e36" }

    use "ethanholz/nvim-lastplace" -- auto return back to the last modified positon when open a file
    -- use "BurntSushi/ripgrep" -- ripgrep
    use "nvim-pack/nvim-spectre" -- search and replace pane
    use "tpope/vim-repeat" --  . command enhance
    use "tpope/vim-surround" -- vim surround

    use { "phaazon/hop.nvim", tag = "v2.0.3" }

    -- snippets
    use "L3MON4D3/LuaSnip" -- snippet engine
    use "rafamadriz/friendly-snippets" -- a bunch of snippets to use

    -- Git
    use { "lewis6991/gitsigns.nvim", tag = "v0.6" }
    use 'sindrets/diffview.nvim'

    -- UI
    -- Colorschemes
    use "lunarvim/colorschemes" -- A bunch of colorschemes you can try out
    use "norcalli/nvim-colorizer.lua" -- show color
    use "folke/trouble.nvim"
    use {"j-hui/fidget.nvim", tag = "legacy"} -- show lsp progress
    use "sindrets/winshift.nvim" -- rerange window layout
    use 'AlexvZyl/nordic.nvim'
    use { "lukas-reineke/indent-blankline.nvim", tag = "v2.20.8" }
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
