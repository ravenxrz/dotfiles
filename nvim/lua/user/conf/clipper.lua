-- NOTE 本插件依赖 netcat bin file， 在 .dotfile/bin/linux 目录下客找到
vim.cmd([[
  let g:ClipperAddress="127.0.0.1"
  let g:ClipperPort=8377
  let g:ClipperAuto=1

  call clipper#set_invocation('netcat -c 127.0.0.1 8377')
]])
