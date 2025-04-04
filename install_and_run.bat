@echo off
setlocal EnableDelayedExpansion

:: Thiết lập biến
set "PYTHON_URL=https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe"
set "PYTHON_INSTALLER=python-installer.exe"
set "PYTHON_MIN_VERSION=3.7"
set "PYTHON_SCRIPT=script.py"
set "CHROME_URL=https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
set "CHROME_INSTALLER=chrome-installer.exe"

:: Kiểm tra quyền Administrator
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Loi: Vui long chay script voi quyen Administrator.
    echo Nhap chuot phai vao file .bat va chon "Run as Administrator".
    pause
    exit /b 1
)

:: Kiểm tra xem file script.py có tồn tại không
if not exist "%~dp0%PYTHON_SCRIPT%" (
    echo Loi: File %PYTHON_SCRIPT% khong ton tai trong thu muc hien hanh.
    echo Vui long dam bao file %PYTHON_SCRIPT% nam cung thu muc voi script nay.
    pause
    exit /b 1
)

:: Kiểm tra kết nối internet
echo Kiem tra ket noi internet...
ping www.google.com -n 1 >nul
if %ERRORLEVEL% neq 0 (
    echo Loi: Khong co ket noi internet. Vui long kiem tra va thu lai.
    pause
    exit /b 1
)

:: Kiểm tra Python
echo Kiem tra Python...
where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=2 delims= " %%v in ('python --version 2^>nul') do set "PYTHON_VERSION=%%v"
    echo Phien ban Python hien tai: !PYTHON_VERSION!
    
    :: So sánh phiên bản Python
    set "VERSION_OKAY=0"
    for /f "tokens=1,2 delims=." %%a in ("!PYTHON_VERSION!") do (
        set "MAJOR=%%a"
        set "MINOR=%%b"
        if !MAJOR! geq 3 (
            if !MINOR! geq 7 (
                set "VERSION_OKAY=1"
            )
        )
    )
    if !VERSION_OKAY! equ 1 (
        echo Python phien ban phu hop ^(>=3.7^), tiep tuc...
        goto :python_ready
    ) else (
        echo Python phien ban qua cu ^(!PYTHON_VERSION!^). Can phien ban 3.7 hoac cao hon.
    )
) else (
    echo Python khong duoc cai dat tren may.
)

:: Tải Python
echo Dang tai Python tu %PYTHON_URL%...
powershell -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'"
if not exist "%PYTHON_INSTALLER%" (
    echo Loi: Khong the tai Python. Kiem tra ket noi internet va thu lai.
    pause
    exit /b 1
)

:: Cài đặt Python
echo Dang cai dat Python...
%PYTHON_INSTALLER% /quiet InstallAllUsers=1 PrependPath=1
if %ERRORLEVEL% neq 0 (
    echo Loi: Cai dat Python that bai.
    del %PYTHON_INSTALLER%
    pause
    exit /b 1
)

:: Xóa file cài đặt Python
del %PYTHON_INSTALLER%
echo Cai dat Python thanh cong.

:: Cập nhật PATH
set "PATH=%PATH%;%ProgramFiles%\Python311\Scripts\;%ProgramFiles%\Python311\"

:python_ready
:: Kiểm tra lại Python
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Loi: Python van khong hoat dong sau khi cai dat. Kiem tra lai.
    pause
    exit /b 1
)

:: Kiểm tra Chrome
echo Kiem tra Google Chrome...
set "CHROME_FOUND=0"
for %%p in (
    "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
    "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do (
    if exist "%%p" (
        set "CHROME_FOUND=1"
        echo Chrome da duoc cai dat tai: %%p
    )
)
if !CHROME_FOUND! equ 0 (
    echo Chrome khong duoc cai dat tren may. Dang tai va cai dat Chrome...
    
    :: Tải Chrome
    powershell -Command "Invoke-WebRequest -Uri '%CHROME_URL%' -OutFile '%CHROME_INSTALLER%'"
    if not exist "%CHROME_INSTALLER%" (
        echo Loi: Khong the tai Chrome. Kiem tra ket noi internet va thu lai.
        pause
        exit /b 1
    )
    
    :: Cài đặt Chrome
    echo Dang cai dat Chrome...
    %CHROME_INSTALLER% /silent /install
    if %ERRORLEVEL% neq 0 (
        echo Loi: Cai dat Chrome that bai.
        del %CHROME_INSTALLER%
        pause
        exit /b 1
    )
    
    :: Xóa file cài đặt Chrome
    del %CHROME_INSTALLER%
    echo Cai dat Chrome thanh cong.
)

:: Chạy script Python
echo Dang chay script Python...
python "%~dp0%PYTHON_SCRIPT%"
if %ERRORLEVEL% neq 0 (
    echo Loi: Khong the chay script Python. Kiem tra lai file %PYTHON_SCRIPT%.
    pause
    exit /b 1
)

echo Hoan tat.
pause
exit /b 0