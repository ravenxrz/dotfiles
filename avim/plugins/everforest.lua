return {
  "sainnhe/everforest",
  config = function ()
    vim.cmd([[
       " Set contrast.
        " This configuration option should be placed before `colorscheme everforest`.
        " Available values: 'hard', 'medium'(default), 'soft'
        let g:everforest_background = 'hard'
        " For better performance
        let g:everforest_better_performance = 1
    ]])
  end
}
