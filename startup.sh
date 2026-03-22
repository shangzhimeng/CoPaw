#!/bin/bash
# CoPaw 一键启动脚本
# 使用方法: ./startup.sh

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 进入项目目录
cd "$SCRIPT_DIR"

# 激活虚拟环境并启动 CoPaw
echo "🚀 正在启动 CoPaw..."
source .venv/Scripts/activate

# 检查是否已初始化
if [ ! -d "$HOME/.copaw" ]; then
    echo "📝 首次运行，正在初始化..."
    copaw init --defaults
fi

# 启动服务
echo "🌐 启动服务，请访问 http://127.0.0.1:8088"
copaw app