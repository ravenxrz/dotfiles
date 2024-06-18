 set auto-load safe-path /

# NOTE: 如果set print pretty on 不生效
# 在 /usr/local/gdb/share/gdb 目录(gdb的安装目录)下, 创建软链接
# ln -s /usr/share/gdb/auto-load auto-load 即可
set print pretty on

# 保存gdb历史命令
set history save on

# 不需要confirm
set confirm off

# 不需要分页
set pagination off

# 开启log
set logging file ./gdb.log
set logging on

# macos 防卡住
# set startup-with-shell off
# 退出gdb quit
define hook-quit
    shell rm .bps.txt
    save breakpoints .bps.txt
    set confirm off
end

# 计算某段内存的md5
define md5m
  set $start_address = $arg0
  set $end_address = $arg1
  set $file_name = "tmp"
   # printf "start addr:%p\n", $start_address
   # printf "end addr:%p\n", $end_address
   # printf "file name :%s\n", $file_name
   eval "dump binary memory %s %p %p", $file_name, $start_address, $end_address
   eval "shell md5sum %s", $file_name
end

document md5m
  Calculate the MD5 hash of a memory range and print it.
  Usage: md5_memory <start address> <end address>
end

define export_deltas
	if $argc != 1
		echo "input delta size"
	end
	set $i = 0	
	while ($i < $arg0)
	    set $lsn = deltas[i].lsn
	    set $buffer = (char *)(deltas[i]).buffer
	    set $len = (deltas[i]).len
	    eval "dump binary memory %lu %p %p", deltas[$i].lsn, deltas[$i].buffer, deltas[$i].buffer + deltas[$i].len
	    set $i = $i + 1
	end
end

document export_deltas
  Export delta buffers, file_name is lsn
  Usage: export_deltas <delta_num>
end

