@echo off
setlocal EnableDelayedExpansion

:: Định nghĩa các biến
set "PYTHON_URL=https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe"
set "PYTHON_INSTALLER=python-installer.exe"
set "PYTHON_SCRIPT=script.py"

:: Ghi log để debug
echo Starting script... > log.txt

:: Kiểm tra quyền admin
echo Checking for administrator privileges... >> log.txt
net session >nul 2>&1 || (echo Error: This script requires administrator privileges. Please run as administrator. >> log.txt && echo Error: This script requires administrator privileges. Please run as administrator. && pause && exit /b 1)

:: Kiểm tra sự tồn tại của script.py
echo Checking for script.py... >> log.txt
if not exist "%~dp0%PYTHON_SCRIPT%" (echo Error: script.py not found in the same directory as this batch file. >> log.txt && echo Error: script.py not found in the same directory as this batch file. && pause && exit /b 1)

:: Kiểm tra kết nối internet
echo Checking internet connection... >> log.txt
ping www.google.com -n 1 >nul || (echo Error: No internet connection. Please check your network and try again. >> log.txt && echo Error: No internet connection. Please check your network and try again. && pause && exit /b 1)

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

:: Tải Python installer
echo Downloading Python installer... >> log.txt
powershell -Command "iwr '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'" || (echo Error: Failed to download Python installer. >> log.txt && echo Error: Failed to download Python installer. && pause && exit /b 1)

:: Kiểm tra file Python installer
echo Verifying Python installer... >> log.txt
if not exist "%PYTHON_INSTALLER%" (echo Error: Python installer not found after download. >> log.txt && echo Error: Python installer not found after download. && pause && exit /b 1)

:: Kiểm tra kích thước file (khoảng 13-14 MB, tức 13,000,000 - 14,000,000 bytes)
for %%F in (%PYTHON_INSTALLER%) do set "FILESIZE=%%~zF"
if %FILESIZE% LSS 13000000 (echo Error: Python installer file is too small (%FILESIZE% bytes). It might be corrupted. >> log.txt && echo Error: Python installer file is too small (%FILESIZE% bytes). It might be corrupted. && pause && exit /b 1)
if %FILESIZE% GTR 15000000 (echo Error: Python installer file is too large (%FILESIZE% bytes). It might be corrupted. >> log.txt && echo Error: Python installer file is too large (%FILESIZE% bytes). It might be corrupted. && pause && exit /b 1)

:: Cài đặt Python (bỏ InstallAllUsers=1 để tránh lỗi quyền, thêm /passive để hiển thị tiến trình cài đặt)
echo Installing Python... >> log.txt
%PYTHON_INSTALLER% /passive PrependPath=1 || (echo Error: Failed to install Python. Check if the installer is valid and you have sufficient permissions. >> log.txt && echo Error: Failed to install Python. Check if the installer is valid and you have sufficient permissions. && pause && exit /b 1)

:: Xóa file Python installer
echo Cleaning up Python installer... >> log.txt
del %PYTHON_INSTALLER% || (echo Warning: Failed to delete Python installer. >> log.txt && echo Warning: Failed to delete Python installer. && pause)

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
