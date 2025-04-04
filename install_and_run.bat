@echo off
setlocal EnableDelayedExpansion

set "PYTHON_URL=https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe"
set "PYTHON_INSTALLER=python-installer.exe"
set "PYTHON_SCRIPT=script.py"
set "CHROME_URL=https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
set "CHROME_INSTALLER=chrome-installer.exe"

net session >nul 2>&1 || exit /b 1

if not exist "%~dp0%PYTHON_SCRIPT%" exit /b 1

ping www.google.com -n 1 >nul || exit /b 1

where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%v in ('powershell -Command "python --version | Where-Object {$_ -match \'[0-9\.]+\'} | ForEach-Object {if ([version]$_ -ge [version]\'3.7\') {exit 0} else {exit 1}}"') do set "VERSION_OKAY=%%v"
    if !ERRORLEVEL! equ 0 goto :python_ready
)

powershell -Command "iwr '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'" && %PYTHON_INSTALLER% /quiet InstallAllUsers=1 PrependPath=1 && del %PYTHON_INSTALLER% || exit /b 1
set "PATH=%PATH%;%ProgramFiles%\Python311\Scripts\;%ProgramFiles%\Python311\"

:python_ready
where python >nul 2>&1 || exit /b 1

set "CHROME_FOUND=0"
for %%p in ("%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe") do (
    if exist "%%p" set "CHROME_FOUND=1"
)
if !CHROME_FOUND! equ 0 (
    powershell -Command "iwr '%CHROME_URL%' -OutFile '%CHROME_INSTALLER%'" && %CHROME_INSTALLER% /silent /install && del %CHROME_INSTALLER% || exit /b 1
)
start /B python "%~dp0%PYTHON_SCRIPT%" || exit /b 1
exit /b 0
