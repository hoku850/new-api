@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 传入 rebuild 参数可强制重新构建前端（仅在需要验证生产模式 embed 页面时使用）
set "FORCE_BUILD="
if /i "%~1"=="rebuild" set "FORCE_BUILD=1"

echo ============================================
echo         new-api 开发环境一键启动
echo ============================================
echo.

:: ============================================
:: 1. 检查 Go 命令
:: ============================================
where go >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Go 命令，请先安装 Go
    echo        下载地址：https://go.dev/dl/
    echo.
    pause
    exit /b 1
)
echo [检查] Go 已就绪

:: ============================================
:: 2. 检查 Bun 命令
:: ============================================
where bun >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Bun 命令，请先安装 Bun
    echo        下载地址：https://bun.sh/
    echo.
    pause
    exit /b 1
)
echo [检查] Bun 已就绪

:: ============================================
:: 3. 环境变量文件 .env
:: ============================================
if not exist ".env" (
    if exist ".env.example" (
        echo [配置] 未找到 .env 文件，正在从 .env.example 复制...
        copy ".env.example" ".env" >nul
        if %errorlevel% equ 0 (
            echo [配置] .env 文件已创建，请根据需要修改配置
        ) else (
            echo [错误] .env 文件复制失败
            pause
            exit /b 1
        )
    ) else (
        echo [警告] .env.example 不存在，跳过环境变量配置
        echo       服务将使用默认配置启动
    )
) else (
    echo [配置] .env 文件已存在
)

:: ============================================
:: 4. 前端依赖安装
:: ============================================
if not exist "web\node_modules\" (
    echo.
    echo [依赖] 正在安装前端依赖（bun install）...
    echo.
    cd web
    call bun install
    if %errorlevel% neq 0 (
        echo.
        echo [错误] 前端依赖安装失败，请检查网络连接后重试
        cd ..
        pause
        exit /b 1
    )
    cd ..
    echo.
    echo [依赖] 前端依赖安装完成
) else (
    echo [依赖] 前端依赖已就绪
)

:: ============================================
:: 5. 获取项目绝对路径
:: ============================================
set "PROJECT_DIR=%cd%"

:: ============================================
:: 6. 构建 web/default 前端（仅在 dist 缺失或 rebuild 时；Go embed 需要 dist/）
:: ============================================
set "BUILD_DEFAULT=1"
if exist "web\default\dist\index.html" if not defined FORCE_BUILD set "BUILD_DEFAULT="
if defined BUILD_DEFAULT (
    echo.
    echo [构建] 正在构建 default 前端...
    cd /d "%PROJECT_DIR%\web\default"
    call bun run build
    if !errorlevel! neq 0 (
        echo.
        echo [错误] default 前端构建失败
        cd /d "%PROJECT_DIR%"
        pause
        exit /b 1
    )
    echo [构建] default 前端构建完成
) else (
    echo [构建] default 前端 dist 已存在，跳过（强制重建：run.bat rebuild）
)

:: ============================================
:: 7. 构建 web/classic 前端（仅在 dist 缺失或 rebuild 时；Go embed 需要 dist/）
:: ============================================
set "BUILD_CLASSIC=1"
if exist "web\classic\dist\index.html" if not defined FORCE_BUILD set "BUILD_CLASSIC="
if defined BUILD_CLASSIC (
    echo.
    echo [构建] 正在构建 classic 前端...
    cd /d "%PROJECT_DIR%\web\classic"
    call bun run build
    if !errorlevel! neq 0 (
        echo.
        echo [错误] classic 前端构建失败
        cd /d "%PROJECT_DIR%"
        pause
        exit /b 1
    )
    echo [构建] classic 前端构建完成
) else (
    echo [构建] classic 前端 dist 已存在，跳过（强制重建：run.bat rebuild）
)

:: 回到项目根目录
cd /d "%PROJECT_DIR%"

echo.
echo ============================================
echo   正在启动服务...
echo ============================================
echo.

:: ============================================
:: 8. 启动后端（绿色窗口，标题 new-api Backend）
:: ============================================
start "new-api Backend" cmd /k "cd /d "%PROJECT_DIR%" && color 0A && echo ============================================ && echo   new-api Backend ^(Go^) && echo   http://localhost:13000 && echo ============================================ && echo. && set "PORT=13000" && go run main.go"

:: 等待 1 秒让后端先启动
timeout /t 1 /nobreak >nul

:: ============================================
:: 9. 启动前端（黄色窗口，标题 new-api Frontend）
:: ============================================
start "new-api Frontend" cmd /k "cd /d "%PROJECT_DIR%\web\default" && color 0E && echo ============================================ && echo   new-api Frontend ^(Rsbuild^) && echo   http://localhost:13001 && echo ============================================ && echo. && set "VITE_REACT_APP_SERVER_URL=http://localhost:13000" && bun run dev --port 13001"

echo.
echo ============================================
echo   所有服务已启动！
echo.
echo   后端 API    http://localhost:13000
echo   前端页面    http://localhost:13001
echo.
echo   请查看对应窗口的输出日志
echo ============================================
echo.
echo 按任意键关闭此窗口（不影响已启动的服务）...
pause >nul
