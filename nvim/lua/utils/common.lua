-- this file define some utils function for myself
-- author: zhangxingrui
function P(t)
  print(vim.inspect(t))
end

function table2str(t)
  return vim.inspect(t)
end

function get_os_platform()
  local handle = io.popen("uname -s 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if string.find(result, "Linux", 1, true) then
      return "Linux"
    elseif string.find(result, "Darwin", 1, true) then
      return "MacOS"
    end
  end

  -- 尝试检查 Windows 环境变量
  local os_env = os.getenv("OS")
  if os_env and string.find(os_env, "Windows", 1, true) then
    return "Windows"
  end
  return "Unknown"
end
