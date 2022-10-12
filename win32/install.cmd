@echo off
setlocal enableextensions enabledelayedexpansion

powershell -nop -ExecutionPolicy Bypass -File %~dp0.\scripts\installer.ps1 %*

exit /b