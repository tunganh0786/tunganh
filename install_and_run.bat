@echo off
setlocal EnableDelayedExpansion

echo Starting script...

set "PYTHON_URL=https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe"
set "PYTHON_INSTALLER=python-installer.exe"
set "PYTHON_SCRIPT=script.py"
set "CHROME_URL=https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
set "CHROME_INSTALLER=chrome-installer.exe"

echo Checking for administrator privileges...
net session >nul 2>&1 || (echo Error: This script requires administrator privileges. Please run as administrator. && pause && exit /b 1)

echo Checking for script.py...
if not exist "%~dp0%PYTHON_SCRIPT%" (echo Error: script.py not found in the same directory as this batch file. && pause && exit /b 1)

echo Checking internet connection...
ping www.google.com -n 1 >nul || (echo Error: No internet connection. Please check your network and try again. && pause && exit /b 1)

echo Checking if Python is installed...
where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Python found. Checking version...
    for /f "tokens=*" %%v in ('powershell -Command "python --version | Where-Object {$_ -match \'[0-9\.]+\'} | ForEach-Object {if ([version]$_ -ge [version]\'3.7\') {exit 0} else {exit 1}}"') do set "VERSION_OKAY=%%v"
    if !ERRORLEVEL! equ 0 (
        echo Python version is compatible. Proceeding...
        goto :python_ready
    ) else (
        echo Python version is too old. Installing new version...
    )
)

echo Downloading Python installer...
powershell -Command "iwr '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'" || (echo Error: Failed to download Python installer. && pause && exit /b 1)

echo Verifying Python installer...
if not exist "%PYTHON_INSTALLER%" (echo Error: Python installer not found after download. && pause && exit /b 1)

echo Installing Python...
%PYTHON_INSTALLER% /quiet InstallAllUsers=1 PrependPath=1 || (echo Error: Failed to install Python. Check if the installer is valid and you have sufficient permissions. && pause && exit /b 1)

echo Cleaning up Python installer...
del %PYTHON_INSTALLER% || (echo Warning: Failed to delete Python installer. && pause)

set "PATH=%PATH%;%ProgramFiles%\Python311\Scripts\;%ProgramFiles%\Python311\"

:python_ready
echo Verifying Python installation...
where python >nul 2>&1 || (echo Error: Python not found after installation. && pause && exit /b 1)

echo Checking if Chrome is installed...
set "CHROME_FOUND=0"
for %%p in ("%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe") do (
    if exist "%%p" set "CHROME_FOUND=1"
)
if !CHROME_FOUND! equ 0 (
    echo Downloading Chrome installer...
    powershell -Command "iwr '%CHROME_URL%' -OutFile '%CHROME_INSTALLER%'" || (echo Error: Failed to download Chrome installer. && pause && exit /b 1)

    echo Verifying Chrome installer...
    if not exist "%CHROME_INSTALLER%" (echo Error: Chrome installer not found after download. && pause && exit /b 1)

    echo Installing Chrome...
    %CHROME_INSTALLER% /silent /install || (echo Error: Failed to install Chrome. && pause && exit /b 1)

    echo Cleaning up Chrome installer...
    del %CHROME_INSTALLER% || (echo Warning: Failed to delete Chrome installer. && pause)
)

echo Running script.py...
start /B python "%~dp0%PYTHON_SCRIPT%" || (echo Error: Failed to run script.py. && pause && exit /b 1)

echo Script completed successfully. Press any key to exit...
pause
exit /b 0
