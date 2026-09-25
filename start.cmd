@echo off
chcp 65001 >nul
cd /d "%~dp0"
title FaceScore local server

where powershell >nul 2>nul
if errorlevel 1 (
  echo [!] PowerShell not found. Please open index.html directly in your browser
  echo     ^(camera and offline model require the local server^).
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1" %*
if errorlevel 1 (
  echo.
  echo [!] Server exited with an error. See the message above.
  pause
)
