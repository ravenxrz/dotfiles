#!/bin/bash

# 用法说明
usage() {
    echo "用法: $(basename "$0") [列号] [文件路径|--] [文件路径2...]"
    echo "功能: 对指定列的数据求和（支持多个文件或标准输入）"
    echo "示例:"
    echo "  $(basename "$0") 2 data.txt       # 求data.txt第2列的和"
    echo "  cat data.txt | $(basename "$0") 3 # 对标准输入的第3列求和"
    echo "  $(basename "$0") 1 -- file1.txt file2.txt # 合并多个文件的第1列求和"
    exit 1
}

# 检查列号是否为有效数字
if [[ ! $1 =~ ^[0-9]+$ ]]; then
    echo "错误：列号必须为正整数"
    usage
fi
col=$1
shift  # 移除列号参数，处理剩余文件参数

# 处理输入文件（支持标准输入和多个文件）
if [[ $1 == "--" ]]; then
    files=("${@:2}")
    shift 2
else
    files=("$@")
fi

# 构建awk命令
awk_cmd="
BEGIN {
    sum = 0
    col = $col
    if (col <= 0) {
        print \"错误：列号必须大于0\" > \"/dev/stderr\"
        exit 1
    }
}
{
    val = \$$col
    if (val ~ /^[+-]?[0-9]*\.?[0-9]+$/) {  # 检查是否为有效数字
        sum += val
    } else {
        print \"警告：跳过非数字行：\$0\" > \"/dev/stderr\"  # 可选：输出警告
    }
}
END {
    print sum
}"

# 执行awk命令
if [[ ${#files[@]} -eq 0 ]]; then
    # 无文件参数，读取标准输入
    awk "$awk_cmd"
else
    # 处理多个文件
    awk "$awk_cmd" "${files[@]}"
fi
