@echo off
setlocal
cd /d "%~dp0"
if exist ".tools\node-v20.11.1-win-x64\node.exe" (
  set "PATH=%CD%\.tools\node-v20.11.1-win-x64;%CD%\.tools\node-v20.11.1-win-x64\node_modules\npm\bin;%PATH%"
)
npm start
