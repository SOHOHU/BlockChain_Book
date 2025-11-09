@echo off
chcp 65001 >nul
echo ========================================
echo   Buy Me A Coffee - 启动脚本
echo ========================================
echo.

echo [1/3] 检查前端目录...
if not exist "frontend\package.json" (
    echo ❌ 错误：找不到 frontend 目录
    echo 请确保在项目根目录运行此脚本
    pause
    exit /b 1
)
echo ✓ 前端目录检查通过
echo.

echo [2/3] 检查依赖是否已安装...
if not exist "frontend\node_modules" (
    echo 正在安装依赖，请稍候...
    cd frontend
    call npm install
    cd ..
)
echo ✓ 依赖已就绪
echo.

echo [3/3] 启动开发服务器...
echo.
echo ========================================
echo   服务器启动中...
echo   请在浏览器访问：http://localhost:3000
echo ========================================
echo.
echo ⚠️  重要提示：
echo    1. 保持此窗口打开
echo    2. 确保 MetaMask 连接到 Kaia Kairos 测试网
echo    3. 按 Ctrl+C 可以停止服务器
echo.
echo ----------------------------------------
echo.

cd frontend
npm run dev

pause



