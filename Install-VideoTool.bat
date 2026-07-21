@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  VBUILD(TM) VideoTool - Automatic Installer
REM  This installer will:
REM    1. Check/Install Python 3.x
REM    2. Check/Install FFmpeg
REM    3. Set up VideoTool ready to use
REM    4. Create a Desktop shortcut
REM
REM  Run this file as Administrator for best results.
REM  https://github.com/vbuildlanka-oss/Videotool
REM ============================================================

title VBUILD VideoTool - Installer

echo.
echo  ============================================================
echo   VBUILD(TM) VideoTool - Installer
echo  ============================================================
echo.
echo   This installer will set up everything needed to run
echo   VideoTool on your system:
echo.
echo     [1] Python 3.x  (if not already installed)
echo     [2] FFmpeg       (if not already installed)
echo     [3] VideoTool    (configured and ready to use)
echo     [4] Desktop shortcut
echo.
echo  ============================================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo  WARNING: Not running as Administrator.
    echo  Some features (like adding to system PATH) may not work.
    echo  Right-click this file and select "Run as administrator"
    echo  for the best experience.
    echo.
    set /p "CONTINUE_CHOICE=  Continue anyway? (Y/N): "
    if /i "!CONTINUE_CHOICE!" neq "Y" (
        echo  Exiting. Please re-run as Administrator.
        echo.
        echo  Press any key to close...
        pause >nul
        exit /b 0
    )
    echo.
)

REM Set installation directory (where this script is located)
set "INSTALL_DIR=%~dp0"
set "INSTALL_DIR=!INSTALL_DIR:~0,-1!"
set "FFMPEG_DIR=!INSTALL_DIR!\ffmpeg"
set "TEMP_DIR=!INSTALL_DIR!\installer_temp"

echo  Install location: !INSTALL_DIR!
echo.

REM Create temp directory for downloads
if not exist "!TEMP_DIR!" mkdir "!TEMP_DIR!"

REM ============================================================
REM  STEP 1: Check/Install Python
REM ============================================================
echo  ============================================================
echo   STEP 1: Checking Python...
echo  ============================================================
echo.

set "PYTHON_OK=0"
set "PYTHON_CMD="
set "PY_VER=Not installed"

REM Check if python is available
where python >nul 2>nul
if !errorlevel! equ 0 (
    REM Verify it's real Python (not Windows Store redirect)
    python --version >nul 2>nul
    if !errorlevel! equ 0 (
        for /f "tokens=*" %%v in ('python --version 2^>^&1') do set "PY_VER=%%v"
        echo   FOUND: !PY_VER!
        set "PYTHON_OK=1"
        set "PYTHON_CMD=python"
    )
)

if "!PYTHON_OK!"=="0" (
    where python3 >nul 2>nul
    if !errorlevel! equ 0 (
        for /f "tokens=*" %%v in ('python3 --version 2^>^&1') do set "PY_VER=%%v"
        echo   FOUND: !PY_VER!
        set "PYTHON_OK=1"
        set "PYTHON_CMD=python3"
    )
)

if "!PYTHON_OK!"=="0" (
    echo   Python NOT found. Installing Python...
    echo.

    REM Determine system architecture
    if "!PROCESSOR_ARCHITECTURE!"=="AMD64" (
        set "PY_ARCH=amd64"
    ) else (
        set "PY_ARCH=win32"
    )

    REM Download Python installer using PowerShell
    echo   Downloading Python 3.12 installer...
    set "PY_URL=https://www.python.org/ftp/python/3.12.4/python-3.12.4-!PY_ARCH!.exe"
    set "PY_INSTALLER=!TEMP_DIR!\python_installer.exe"

    echo   URL: !PY_URL!
    echo   Please wait...
    echo.

    powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; try { (New-Object Net.WebClient).DownloadFile('!PY_URL!', '!PY_INSTALLER!') } catch { Write-Host \"DOWNLOAD_FAILED: $_\"; exit 1 }"

    if not exist "!PY_INSTALLER!" (
        echo.
        echo   ERROR: Failed to download Python installer.
        echo   Please download Python manually from:
        echo     https://www.python.org/downloads/
        echo   Make sure to check "Add Python to PATH" during install.
        echo.
        goto :python_done
    )

    echo   Installing Python (this may take a minute)...
    echo   Options: Add to PATH, install for all users
    echo.

    REM Install Python silently with PATH option
    "!PY_INSTALLER!" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=1

    if !errorlevel! neq 0 (
        echo   Silent install requires Admin. Launching interactive installer...
        echo   IMPORTANT: Check "Add Python to PATH" at the bottom of the installer!
        echo.
        echo   Waiting for installation to complete...
        "!PY_INSTALLER!" PrependPath=1
    )

    REM Refresh PATH
    call :RefreshPath

    REM Verify Python installation
    where python >nul 2>nul
    if !errorlevel! equ 0 (
        for /f "tokens=*" %%v in ('python --version 2^>^&1') do set "PY_VER=%%v"
        echo   SUCCESS: !PY_VER! installed.
        set "PYTHON_OK=1"
        set "PYTHON_CMD=python"
    ) else (
        echo   Python installed but not yet in PATH for this session.
        echo   Checking common install locations...

        REM Try common install locations
        if exist "C:\Python312\python.exe" (
            set "PYTHON_CMD=C:\Python312\python.exe"
            set "PYTHON_OK=1"
        ) else if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
            set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
            set "PYTHON_OK=1"
        ) else if exist "C:\Program Files\Python312\python.exe" (
            set "PYTHON_CMD=C:\Program Files\Python312\python.exe"
            set "PYTHON_OK=1"
        )

        if "!PYTHON_OK!"=="1" (
            for /f "tokens=*" %%v in ('"!PYTHON_CMD!" --version 2^>^&1') do set "PY_VER=%%v"
            echo   Found Python at: !PYTHON_CMD!
        )
    )
)

:python_done
if "!PYTHON_OK!"=="0" (
    echo.
    echo   *** Python installation could not be verified. ***
    echo   Please install Python manually and re-run this installer.
    echo   Download: https://www.python.org/downloads/
    echo.
    set /p "PY_CONT=  Continue without Python? (Y/N): "
    if /i "!PY_CONT!" neq "Y" goto :cleanup
    set "PYTHON_CMD=python"
)

echo.

REM ============================================================
REM  STEP 2: Check/Install FFmpeg
REM ============================================================
echo  ============================================================
echo   STEP 2: Checking FFmpeg...
echo  ============================================================
echo.

set "FFMPEG_OK=0"
set "FFMPEG_PATH=Not installed"

REM Check if ffmpeg is in PATH
where ffmpeg >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%p in ('where ffmpeg') do set "FFMPEG_PATH=%%p"
    echo   FOUND: !FFMPEG_PATH!
    set "FFMPEG_OK=1"
    goto :ffmpeg_done
)

REM Check in tool directory
if exist "!INSTALL_DIR!\ffmpeg.exe" (
    echo   FOUND: !INSTALL_DIR!\ffmpeg.exe
    set "FFMPEG_OK=1"
    set "FFMPEG_PATH=!INSTALL_DIR!\ffmpeg.exe"
    goto :ffmpeg_done
)

REM Check in ffmpeg subfolder
if exist "!FFMPEG_DIR!\bin\ffmpeg.exe" (
    echo   FOUND: !FFMPEG_DIR!\bin\ffmpeg.exe
    set "FFMPEG_OK=1"
    set "FFMPEG_PATH=!FFMPEG_DIR!\bin\ffmpeg.exe"
    goto :ffmpeg_done
)

if exist "!FFMPEG_DIR!\ffmpeg.exe" (
    echo   FOUND: !FFMPEG_DIR!\ffmpeg.exe
    set "FFMPEG_OK=1"
    set "FFMPEG_PATH=!FFMPEG_DIR!\ffmpeg.exe"
    goto :ffmpeg_done
)

REM FFmpeg not found - download it
echo   FFmpeg NOT found. Downloading FFmpeg...
echo.

REM Create ffmpeg directory
if not exist "!FFMPEG_DIR!" mkdir "!FFMPEG_DIR!"

REM Download FFmpeg release build using PowerShell
echo   Downloading FFmpeg (this may take a few minutes)...
echo   Please wait...
set "FFMPEG_ZIP=!TEMP_DIR!\ffmpeg.zip"
set "FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

echo   Source: !FFMPEG_URL!
echo.

powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '!FFMPEG_URL!' -OutFile '!FFMPEG_ZIP!' -UseBasicParsing -TimeoutSec 300 } catch { Write-Host \"DOWNLOAD_FAILED: $_\"; exit 1 }"

if not exist "!FFMPEG_ZIP!" (
    echo   Primary download failed. Trying alternate source...
    set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    echo   Source: !FFMPEG_URL!

    powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '!FFMPEG_URL!' -OutFile '!FFMPEG_ZIP!' -UseBasicParsing -TimeoutSec 300 } catch { Write-Host \"DOWNLOAD_FAILED: $_\"; exit 1 }"
)

if not exist "!FFMPEG_ZIP!" (
    echo.
    echo   ERROR: Failed to download FFmpeg.
    echo   Please download FFmpeg manually from:
    echo     https://ffmpeg.org/download.html
    echo   Then place ffmpeg.exe in: !INSTALL_DIR!
    echo.
    goto :ffmpeg_done
)

echo   Download complete. Extracting FFmpeg...

REM Extract using PowerShell
powershell -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; try { [System.IO.Compression.ZipFile]::ExtractToDirectory('!FFMPEG_ZIP!', '!TEMP_DIR!\ffmpeg_extract') } catch { Write-Host \"EXTRACT_FAILED: $_\"; exit 1 }"

REM Find ffmpeg.exe in extracted files and copy to our ffmpeg folder
set "FF_COPIED=0"
for /r "!TEMP_DIR!\ffmpeg_extract" %%f in (ffmpeg.exe) do (
    if exist "%%f" if "!FF_COPIED!"=="0" (
        copy "%%f" "!FFMPEG_DIR!\ffmpeg.exe" >nul 2>nul
        set "FFMPEG_OK=1"
        set "FFMPEG_PATH=!FFMPEG_DIR!\ffmpeg.exe"
        set "FF_COPIED=1"
    )
)

REM Also grab ffprobe.exe if available
for /r "!TEMP_DIR!\ffmpeg_extract" %%f in (ffprobe.exe) do (
    if exist "%%f" (
        copy "%%f" "!FFMPEG_DIR!\ffprobe.exe" >nul 2>nul
    )
)

if "!FFMPEG_OK!"=="1" (
    echo   SUCCESS: FFmpeg installed to !FFMPEG_DIR!\

    REM Add ffmpeg to user PATH permanently
    echo   Adding FFmpeg to user PATH...
    powershell -ExecutionPolicy Bypass -Command "$path = [Environment]::GetEnvironmentVariable('PATH', 'User'); if ($path -notlike '*!FFMPEG_DIR!*') { [Environment]::SetEnvironmentVariable('PATH', $path + ';!FFMPEG_DIR!', 'User'); Write-Host '   Added to PATH' } else { Write-Host '   Already in PATH' }"
    set "PATH=!PATH!;!FFMPEG_DIR!"
) else (
    echo   WARNING: Could not extract FFmpeg.
    echo   Please install FFmpeg manually from https://ffmpeg.org/download.html
)

:ffmpeg_done
echo.

REM ============================================================
REM  STEP 3: Verify VideoTool files
REM ============================================================
echo  ============================================================
echo   STEP 3: Verifying VideoTool files...
echo  ============================================================
echo.

set "TOOL_OK=1"

if exist "!INSTALL_DIR!\videotool.py" (
    echo   [OK] videotool.py
) else (
    echo   [MISSING] videotool.py
    set "TOOL_OK=0"
)

if exist "!INSTALL_DIR!\VideoTool.bat" (
    echo   [OK] VideoTool.bat
) else (
    echo   [MISSING] VideoTool.bat
    set "TOOL_OK=0"
)

if exist "!INSTALL_DIR!\VideoTool-DragDrop.bat" (
    echo   [OK] VideoTool-DragDrop.bat
) else (
    echo   [MISSING] VideoTool-DragDrop.bat
    set "TOOL_OK=0"
)

if "!TOOL_OK!"=="0" (
    echo.
    echo   WARNING: Some VideoTool files are missing.
    echo   Make sure all files are in: !INSTALL_DIR!
)

echo.

REM ============================================================
REM  STEP 4: Create Desktop Shortcut
REM ============================================================
echo  ============================================================
echo   STEP 4: Creating Desktop shortcuts...
echo  ============================================================
echo.

set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT=!DESKTOP!\VideoTool.lnk"
set "SHORTCUT_DD=!DESKTOP!\VideoTool-DragDrop.lnk"

REM Create main shortcut
powershell -ExecutionPolicy Bypass -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('!SHORTCUT!'); $Shortcut.TargetPath = '!INSTALL_DIR!\VideoTool.bat'; $Shortcut.WorkingDirectory = '!INSTALL_DIR!'; $Shortcut.Description = 'VBUILD VideoTool - C2PA and Metadata Remover'; $Shortcut.Save()"

if exist "!SHORTCUT!" (
    echo   [OK] Desktop shortcut: VideoTool.lnk
) else (
    echo   [SKIP] Could not create VideoTool shortcut
)

REM Create drag-drop shortcut
powershell -ExecutionPolicy Bypass -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('!SHORTCUT_DD!'); $Shortcut.TargetPath = '!INSTALL_DIR!\VideoTool-DragDrop.bat'; $Shortcut.WorkingDirectory = '!INSTALL_DIR!'; $Shortcut.Description = 'VBUILD VideoTool - Drag Videos Here to Clean'; $Shortcut.Save()"

if exist "!SHORTCUT_DD!" (
    echo   [OK] Desktop shortcut: VideoTool-DragDrop.lnk
) else (
    echo   [SKIP] Could not create DragDrop shortcut
)

echo.

REM ============================================================
REM  STEP 5: Run a quick verification
REM ============================================================
echo  ============================================================
echo   STEP 5: Running verification...
echo  ============================================================
echo.

if "!PYTHON_OK!"=="1" (
    "!PYTHON_CMD!" -c "import sys; print(f'   Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro} - OK')" 2>nul
    if !errorlevel! neq 0 (
        echo   [WARN] Python test failed - may need restart
    )
) else (
    echo   [SKIP] Python not verified
)

if "!FFMPEG_OK!"=="1" (
    "!FFMPEG_PATH!" -version >nul 2>nul
    if !errorlevel! equ 0 (
        echo   FFmpeg - OK
    ) else (
        echo   [WARN] FFmpeg test failed - may need restart
    )
) else (
    echo   [SKIP] FFmpeg not verified
)

echo.

REM ============================================================
REM  CLEANUP & SUMMARY
REM ============================================================
:cleanup

REM Remove temp files
if exist "!TEMP_DIR!" (
    echo   Cleaning up temporary files...
    rmdir /s /q "!TEMP_DIR!" >nul 2>nul
)

echo.
echo  ============================================================
echo.
echo   INSTALLATION COMPLETE!
echo.
echo   Summary:
echo   --------
echo   Python:    !PY_VER!
echo   FFmpeg:    !FFMPEG_PATH!
echo   VideoTool: !INSTALL_DIR!
echo.
echo   HOW TO USE:
echo   -----------
echo   1. Double-click "VideoTool" shortcut on your Desktop
echo   2. Or drag video files onto "VideoTool-DragDrop" on Desktop
echo   3. Or run from command line:
echo        VideoTool.bat "C:\path\to\video.mp4"
echo.
echo   Cleaned videos are saved to a "cleaned" subfolder.
echo.
echo   VBUILD(TM) VideoTool - Open Source
echo   https://github.com/vbuildlanka-oss/Videotool
echo.
echo  ============================================================
echo.

if "!PYTHON_OK!"=="0" (
    echo  NOTE: Python was installed but requires a RESTART to work.
    echo  Please restart your computer, then use VideoTool.
    echo.
) else if "!FFMPEG_OK!"=="0" (
    echo  NOTE: FFmpeg could not be installed automatically.
    echo  Please install it manually from https://ffmpeg.org/download.html
    echo.
) else (
    echo  Everything is ready! You can start using VideoTool now.
    echo.
)

echo  Press any key to close...
pause >nul
endlocal
exit /b 0

REM ============================================================
REM  HELPER: Refresh PATH from registry
REM ============================================================
:RefreshPath
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%b"
if defined SYS_PATH if defined USR_PATH set "PATH=!SYS_PATH!;!USR_PATH!"
goto :eof
