@echo off
setlocal EnableDelayedExpansion

:: Định nghĩa các biến
set "PYTHON_SCRIPT=script.py"

:: Ghi log để debug
echo Starting script... > log.txt

:: Kiểm tra sự tồn tại của script.py
echo Checking for script.py... >> log.txt
if not exist "%~dp0%PYTHON_SCRIPT%" (echo Error: script.py not found in the same directory as this batch file. >> log.txt && echo Error: script.py not found in the same directory as this batch file. && pause && exit /b 1)

:: Kiểm tra kết nối internet
echo Checking internet connection... >> log.txt
ping www.google.com -n 1 >nul || (echo Error: No internet connection. Please check your network and try again. >> log.txt && echo Error: No internet connection. Please check your network and try again. && pause && exit /b 1)

:: Kiểm tra và cài đặt Chocolatey nếu chưa có
echo Checking for Chocolatey... >> log.txt
where choco >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Chocolatey not found. Installing Chocolatey... >> log.txt
    powershell -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" || (echo Error: Failed to install Chocolatey. >> log.txt && echo Error: Failed to install Chocolatey. && pause && exit /b 1)
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
)

:: Kiểm tra lại Chocolatey
where choco >nul 2>&1 || (echo Error: Chocolatey not found after installation. >> log.txt && echo Error: Chocolatey not found after installation. && pause && exit /b 1)

:: Kiểm tra xem Python đã được cài đặt chưa
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

:: Cài đặt Python bằng Chocolatey
echo Installing Python using Chocolatey... >> log.txt
choco install python --version=3.11.5 -y || (echo Error: Failed to install Python using Chocolatey. >> log.txt && echo Error: Failed to install Python using Chocolatey. && pause && exit /b 1)

:: Cập nhật PATH
set "PATH=%PATH%;%ProgramFiles%\Python311\Scripts\;%ProgramFiles%\Python311\"

:python_ready
:: Kiểm tra lại Python sau khi cài đặt
echo Verifying Python installation... >> log.txt
where python >nul 2>&1 || (echo Error: Python not found after installation. >> log.txt && echo Error: Python not found after installation. && pause && exit /b 1)

:: Chạy script.py
echo Running script.py... >> log.txt
start /B /wait python "%~dp0%PYTHON_SCRIPT%" || (echo Error: Failed to run script.py. >> log.txt && echo Error: Failed to run script.py. && pause && exit /b 1)

:: Hoàn tất
echo Script completed successfully. Press any key to exit... >> log.txt
echo Script completed successfully. Press any key to exit...
pause
exit /b 0
