@echo off
chcp 65001 >nul
title Yinor Coffee - 网站发布工具
cd /d "%~dp0"

echo ==========================================
echo    Yinor Coffee 网站发布工具
echo    自动构建 + 发布到 yinorcoffee.com
echo ==========================================
echo.

echo [1/4] 检查构建环境...
where node >nul 2>nul
if %errorlevel% neq 0 (
  echo [错误] 找不到 Node.js，无法构建。
  pause
  exit /b 1
)

echo [2/4] 构建网站（src 源码 -^> docs 网站文件）...
node build.js
if %errorlevel% neq 0 (
  echo.
  echo [错误] 构建失败！请检查刚才改动的文件是否写坏了。
  pause
  exit /b 1
)
echo 构建成功。
echo.

echo [3/4] 提交更改...
git add -A
git -c user.name="yinor" -c user.email="yinor@yinorcoffee.com" commit -m "Update site content"
echo.

echo [4/4] 发布到线上（GitHub Pages）...
set AUTH=WWlub3Jjb2ZmZWU6Z2hwX2dETm9mcnVFbFJ3S2VDcWpjbm5meUNjM1ROemtOZDFSdkNRWQ==
git -c http.proxy=http://localhost:1080 -c http.extraheader="AUTHORIZATION: basic %AUTH%" push origin main
if %errorlevel% neq 0 (
  echo.
  echo [提示] 推送失败，尝试不用代理重试...
  git -c http.extraheader="AUTHORIZATION: basic %AUTH%" push origin main
)

echo.
echo ==========================================
echo   完成！等 1-2 分钟后打开 https://yinorcoffee.com 刷新查看
echo   （如果显示旧内容，按 Ctrl+F5 强制刷新）
echo ==========================================
pause
