#!/usr/bin/env bash
set -euo pipefail

# 通用版：为任意 CMake 项目生成 compile_commands.json
# 使用方式（在项目根目录执行）：
#   SRC_DIRS="src include test" ./gen_compile_commands_mac.sh
# 或者显式指定项目根目录和构建目录：
#   PROJECT_ROOT=/path/to/project BUILD_DIR=/path/to/build \
#   SRC_DIRS="src tools" ./gen_compile_commands_mac.sh
#
# 环境变量说明：
#   PROJECT_ROOT  ：项目根目录，默认=当前脚本所在目录
#   BUILD_DIR     ：用于生成 compile_commands.json 的构建目录
#                    默认="$PROJECT_ROOT/build-compile-commands"
#   SRC_DIRS/SCAN_DIRS：要扫描的源码目录（相对 PROJECT_ROOT 或绝对路径）
#                    用空格分隔，例如："src include test tools"
#   CXX_COMPILER  ：C++ 编译器，默认=clang++
#   BUILD_TYPE    ：CMake 构建类型，默认=Debug
#   CMAKE_EXTRA_ARGS：额外透传给 cmake 的参数字符串
#
# 脚本不会真正编译代码，只是配置一个“虚拟”工程，让 CMake
# 产生 compile_commands.json，供 clangd / 其他工具使用。

#=============================
# 1. 解析项目根目录 & 构建目录
#=============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${PROJECT_ROOT:-${SCRIPT_DIR}}"

# 允许通过位置参数覆盖 ROOT_DIR / BUILD_DIR：
#   ./gen_compile_commands_mac.sh /path/to/project /path/to/build
if [[ $# -ge 1 ]]; then
  ROOT_DIR="$(cd "$1" && pwd)"
fi

DEFAULT_BUILD_DIR="${ROOT_DIR}/build-compile-commands"
BUILD_DIR="${BUILD_DIR:-${DEFAULT_BUILD_DIR}}"
if [[ $# -ge 2 ]]; then
  BUILD_DIR="$2"
fi

#=============================
# 2. 要扫描的源码目录列表
#=============================
# 优先级：命令行环境变量 SRC_DIRS > SCAN_DIRS > 默认值
SCAN_DIRS_STR="${SRC_DIRS:-${SCAN_DIRS:-"neon"}}"

# 拆成数组
IFS=' ' read -r -a SCAN_DIRS <<< "${SCAN_DIRS_STR}"

if [[ ${#SCAN_DIRS[@]} -eq 0 ]]; then
  echo "错误：要扫描的目录列表为空，请通过环境变量 SRC_DIRS 或 SCAN_DIRS 配置。" >&2
  exit 1
fi

#=============================
# 3. 为 clangd 生成专用 CMake 工程
#=============================
CMAKE_STUB_DIR="${BUILD_DIR}/cmake_for_clangd"
mkdir -p "${CMAKE_STUB_DIR}"

CMAKE_FILE="${CMAKE_STUB_DIR}/CMakeLists.txt"

echo "==> 生成临时 CMakeLists.txt：${CMAKE_FILE}"

cat > "${CMAKE_FILE}" <<EOF
cmake_minimum_required(VERSION 3.16)

# 这个工程只用于给 clangd 提供 compile_commands.json
project(clangd_index CXX)

# 让 CMake 自动生成 compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 在 macOS 上禁用 CMake 自动设置的 sysroot，避免生成 -isysroot ...
if(APPLE)
    set(CMAKE_OSX_SYSROOT "" CACHE PATH "" FORCE)
endif()

# ===============================
# 配置：要索引的“核心源码目录”
# ===============================
# 这些路径由脚本按需填充，均为绝对路径。
set(SRC_ROOTS
EOF

# 追加 SRC_ROOTS 条目
for dir in "${SCAN_DIRS[@]}"; do
  # 允许相对 PROJECT_ROOT 或绝对路径
  if [[ "${dir}" = /* ]]; then
    abs_dir="${dir}"
  else
    abs_dir="${ROOT_DIR}/${dir}"
  fi

  if [[ -d "${abs_dir}" ]]; then
    printf '    "%s"\n' "${abs_dir}" >> "${CMAKE_FILE}"
  else
    echo "警告：目录不存在，跳过：${abs_dir}" >&2
  fi
done

echo ")" >> "${CMAKE_FILE}"

# 继续写入通用 CMake 逻辑
cat >> "${CMAKE_FILE}" <<'EOF'

# ===============================
# 收集头文件 & 源文件
# ===============================

set(ALL_HEADERS "")
set(ALL_SOURCES "")

foreach(root IN LISTS SRC_ROOTS)
    if (EXISTS "${root}")
        # 递归收集头文件
        file(GLOB_RECURSE HEADERS_IN_ROOT 
            "${root}/*.h"
            "${root}/*.hpp"
            "${root}/*.hh"
        )
        # 递归收集源文件
        file(GLOB_RECURSE SOURCES_IN_ROOT 
            "${root}/*.cc"
            "${root}/*.cpp"
            "${root}/*.cxx"
        )

        foreach(hdr IN LISTS HEADERS_IN_ROOT)
            list(APPEND ALL_HEADERS "${hdr}")
        endforeach()

        foreach(src IN LISTS SOURCES_IN_ROOT)
            list(APPEND ALL_SOURCES "${src}")
        endforeach()
    endif()
endforeach()

# 从头文件列表中提取目录，作为 include 目录
set(INCLUDE_DIRS "")
foreach(header_file IN LISTS ALL_HEADERS)
    get_filename_component(dir "${header_file}" DIRECTORY)
    list(APPEND INCLUDE_DIRS "${dir}")
endforeach()
list(REMOVE_DUPLICATES INCLUDE_DIRS)

# 调试：将收集到的目录和文件路径写入一个文本文件，方便排查
set(CLANGD_DEBUG_FILE "${CMAKE_BINARY_DIR}/clangd_index_debug.txt")

file(WRITE "${CLANGD_DEBUG_FILE}" "=== INCLUDE_DIRS ===\n")
foreach(dir IN LISTS INCLUDE_DIRS)
    file(APPEND "${CLANGD_DEBUG_FILE}" "${dir}\n")
endforeach()

file(APPEND "${CLANGD_DEBUG_FILE}" "\n=== ALL_SOURCES ===\n")
foreach(src IN LISTS ALL_SOURCES)
    file(APPEND "${CLANGD_DEBUG_FILE}" "${src}\n")
endforeach()


# ===============================
# 目标配置（给 clangd 用）
# ===============================

# C++ 标准按实际项目需要调，这里用 17 做例子
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 建一个“虚拟”可执行文件，把所有源文件挂上去
add_executable(dummy_index_target ${ALL_SOURCES})

# 把所有含 .h 的目录当成 include_directories
# 对 clangd 来说，一个 target 就够了

target_include_directories(dummy_index_target PRIVATE ${INCLUDE_DIRS})

# 避免误执行 cmake --build . 时真的去编一大堆东西
set_target_properties(dummy_index_target PROPERTIES
    EXCLUDE_FROM_ALL ON
    EXCLUDE_FROM_DEFAULT_BUILD ON
)
EOF

#=============================
# 4. 运行 CMake 生成 compile_commands.json
#=============================
CXX_COMPILER="${CXX_COMPILER:-clang++}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
CMAKE_EXTRA_ARGS="${CMAKE_EXTRA_ARGS:-}" # 可选：额外传给 cmake

mkdir -p "${BUILD_DIR}"

echo "==> 配置 CMake（仅用于生成 compile_commands.json）"
cmake -S "${CMAKE_STUB_DIR}" \
      -B "${BUILD_DIR}" \
      -DCMAKE_CXX_COMPILER="${CXX_COMPILER}" \
      -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
      ${CMAKE_EXTRA_ARGS}

# 注意：只需要 configure 就会生成 compile_commands.json，
# 不需要 cmake --build

if [[ ! -f "${BUILD_DIR}/compile_commands.json" ]]; then
  echo "错误：${BUILD_DIR}/compile_commands.json 未生成。" >&2
  exit 1
fi

#=============================
# 5. 在项目根目录创建/更新软链接
#=============================

echo "==> 在项目根目录创建/更新软链接 compile_commands.json"
ln -sf "${BUILD_DIR}/compile_commands.json" "${ROOT_DIR}/compile_commands.json"

cat <<EOF
完成：
  编译数据库: ${BUILD_DIR}/compile_commands.json
  根目录链接: ${ROOT_DIR}/compile_commands.json

示例：在 Neovim 中从项目根目录启动：
  cd "${ROOT_DIR}" && nvim src/your_project/xxx.cc
EOF

