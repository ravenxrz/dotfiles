return {
  "wincent/vim-clipper",
  config = function()
    vim.cmd [[
      let g:ClipperAddress="127.0.0.1"
      let g:ClipperPort=8377
      let g:ClipperAuto=1
      call clipper#set_invocation('netcat -c 127.0.0.1 8377')
    ]]
  end,
  lazy = false,
}
