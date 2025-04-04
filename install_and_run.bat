@echo off
setlocal EnableDelayedExpansion

echo Starting script... > log.txt
set "PYTHON_URL=https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe"
set "PYTHON_INSTALLER=python-installer.exe"
set "PYTHON_SCRIPT=script.py"
set "CHROME_URL=https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
set "CHROME_INSTALLER=chrome-installer.exe"

echo Checking for administrator privileges... >> log.txt
net session >nul 2>&1 || (echo Error: This script requires administrator privileges. Please run as administrator. >> log.txt && pause && exit /b 1)

echo Checking for script.py... >> log.txt
if not exist "%~dp0%PYTHON_SCRIPT%" (echo Error: script.py not found in the same directory as this batch file. >> log.txt && pause && exit /b 1)

echo Checking internet connection... >> log.txt
ping www.google.com -n 1 >nul || (echo Error: No internet connection. Please check your network and try again. >> log.txt && pause && exit /b 1)

echo Checking if Python is installed... >> log.txt
where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Python found. Checking version... >> log.txt
    for /f "tokens=*" %%v in ('powershell -Command "python --version | Where-Object {$_ -match \'[0-9\.]+\'} | ForEach-Object {if ([version]$_ -ge [version]\'3.7\') {exit 0} else {exit 1}}"') do set "VERSION_OKAY=%%v"
    if !ERRORLEVEL! equ 0 (
        echo Python version is compatible. Proceeding... >> log.txt
        goto :python_ready
    ) else (
        echo Python version is too old. Installing new version... >> log.txt
    )
)

echo Downloading Python installer... >> log.txt
powershell -Command "iwr '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'" || (echo Error: Failed to download Python installer. >> log.txt && pause && exit /b 1)

echo Verifying Python installer... >> log.txt
if not exist "%PYTHON_INSTALLER%" (echo Error: Python installer not found after download. >> log.txt && pause && exit /b 1)

echo Installing Python... >> log.txt
%PYTHON_INSTALLER% /quiet InstallAllUsers=1 PrependPath=1 || (echo Error: Failed to install Python. Check if the installer is valid and you have sufficient permissions. >> log.txt && pause && exit /b 1)

echo Cleaning up Python installer... >> log.txt
del %PYTHON_INSTALLER% || (echo Warning: Failed to delete Python installer. >> log.txt && pause)

set "PATH=%PATH%;%ProgramFiles%\Python311\Scripts\;%ProgramFiles%\Python311\"

:python_ready
echo Verifying Python installation... >> log.txt
where python >nul 2>&1 || (echo Error: Python not found after installation. >> log.txt && pause && exit /b 1)

echo Checking if Chrome is installed... >> log.txt
set "CHROME_FOUND=0"
for %%p in ("%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe") do (
    if exist "%%p" set "CHROME_FOUND=1"
)
if !CHROME_FOUND! equ 0 (
    echo Downloading Chrome installer... >> log.txt
    powershell -Command "iwr '%CHROME_URL%' -OutFile '%CHROME_INSTALLER%'" || (echo Error: Failed to download Chrome installer. >> log.txt && pause && exit /b 1)

    echo Verifying Chrome installer... >> log.txt
    if not exist "%CHROME_INSTALLER%" (echo Error: Chrome installer not found after download. >> log.txt && pause && exit /b 1)

    echo Installing Chrome... >> log.txt
    %CHROME_INSTALLER% /silent /install || (echo Error: Failed to install Chrome. >> log.txt && pause && exit /b 1)

    echo Cleaning up Chrome installer... >> log.txt
    del %CHROME_INSTALLER% || (echo Warning: Failed to delete Chrome installer. >> log.txt && pause)
)

echo Running script.py... >> log.txt
start /B /wait python "%~dp0%PYTHON_SCRIPT%" || (echo Error: Failed to run script.py. >> log.txt && pause && exit /b 1)

echo Script completed successfully. Press any key to exit... >> log.txt
pause
exit /b 0
