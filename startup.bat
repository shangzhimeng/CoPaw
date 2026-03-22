@echo off
chcp 65001 >nul
REM CoPaw 一键启动脚本 (Windows)
REM 使用方法: 双击运行或在命令行执行 startup.bat

cd /d "%~dp0"

echo 🚀 正在启动 CoPaw...

REM 激活虚拟环境
call .venv\Scripts\activate.bat

REM 检查是否已初始化
if not exist "%USERPROFILE%\.copaw" (
    echo 📝 首次运行，正在初始化...
    copaw init --defaults
)

REM 启动服务
echo 🌐 启动服务，请访问 http://127.0.0.1:8088
copaw app

pause