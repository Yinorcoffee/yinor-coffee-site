@echo off
chcp 65001 >nul
title Yinor Coffee - 网站发布工具
echo ==========================================
echo   Yinor Coffee 网站发布工具
echo   自动构建 + 自动部署到 yinorcoffee.com
echo ==========================================
echo.
echo [1/3] 检查构建环境...
where pwsh >nul 2>nul
if %errorlevel% neq 0 (
  echo 未找到 PowerShell 7，尝试用 Windows PowerShell 5.1...
  set PWSH=powershell
) else (
  set PWSH=pwsh
)
echo.
echo [2/3] 构建网站（把 src 源码生成到 docs）...
%PWSH% -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if %errorlevel% neq 0 (
  echo.
  echo [错误] 构建失败！请检查是否改坏了文件。
  pause
  exit /b 1
)
echo.
echo [3/3] 部署到 Netlify...
set /p NETLIFY_TOKEN=请输入 Netlify 令牌（没有就联系我生成）: 
set NETLIFY_SITE_ID=474fa885-9d93-46d1-b2ae-5132c0c51be8
%PWSH% -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy-netlify.ps1"
echo.
echo ==========================================
echo   完成！打开 yinorcoffee.com 刷新查看
echo ==========================================
pause
