@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  VBUILD(TM) VideoTool - C2PA & EXIF Metadata Remover
REM  Strips C2PA content credentials and all metadata from videos
REM  https://github.com/vbuildlanka-oss/Videotool
REM ============================================================

title VBUILD VideoTool - C2PA Metadata Remover

echo.
echo  ___    ___  ____   __  __  ____  __     ____
echo  \  \  /  / ^| __ ) ^|  ^|^|  ^|^|_  _^|^|  ^|   ^|  _ \
echo   \  \/  /  ^| __ \ ^|  ^|^|  ^| _^|^|_ ^|  ^|__ ^| ^|_) ^|
echo    \    /   ^|____/ \______/^|____^|^|____^| ^|____/
echo     \__/    VideoTool - C2PA ^& Metadata Remover
echo             VBUILD(TM) Open Source Tool
echo.
echo  ============================================================
echo.

REM ---- Locate Python ----
set "PYTHON_CMD="

REM Check python in PATH
where python >nul 2>nul
if !errorlevel! equ 0 (
    REM Make sure it's real Python not the Windows Store stub
    python --version >nul 2>nul
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=python"
        goto :python_found
    )
)

REM Check python3 in PATH
where python3 >nul 2>nul
if !errorlevel! equ 0 (
    set "PYTHON_CMD=python3"
    goto :python_found
)

REM Check common install locations
if exist "C:\Python312\python.exe" (
    set "PYTHON_CMD=C:\Python312\python.exe"
    goto :python_found
)
if exist "C:\Python311\python.exe" (
    set "PYTHON_CMD=C:\Python311\python.exe"
    goto :python_found
)
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    goto :python_found
)
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto :python_found
)

REM Python not found
echo  ERROR: Python is not installed or not in PATH.
echo.
echo  Please run Install-VideoTool.bat first, or install Python manually:
echo    https://www.python.org/downloads/
echo.
echo  Make sure to check "Add Python to PATH" during installation.
echo.
echo  Press any key to exit...
pause >nul
exit /b 1

:python_found
for /f "tokens=*" %%v in ('!PYTHON_CMD! --version 2^>^&1') do echo  Python: %%v

REM ---- Locate FFmpeg ----
set "FFMPEG_FOUND=0"

where ffmpeg >nul 2>nul
if !errorlevel! equ 0 (
    set "FFMPEG_FOUND=1"
    echo  FFmpeg: Found in PATH
)

if "!FFMPEG_FOUND!"=="0" (
    if exist "%~dp0ffmpeg.exe" (
        set "PATH=%~dp0;!PATH!"
        set "FFMPEG_FOUND=1"
        echo  FFmpeg: Found in tool directory
    ) else if exist "%~dp0ffmpeg\ffmpeg.exe" (
        set "PATH=%~dp0ffmpeg;!PATH!"
        set "FFMPEG_FOUND=1"
        echo  FFmpeg: Found in ffmpeg subfolder
    ) else if exist "%~dp0ffmpeg\bin\ffmpeg.exe" (
        set "PATH=%~dp0ffmpeg\bin;!PATH!"
        set "FFMPEG_FOUND=1"
        echo  FFmpeg: Found in ffmpeg\bin subfolder
    )
)

if "!FFMPEG_FOUND!"=="0" (
    echo.
    echo  WARNING: FFmpeg not found!
    echo  Please run Install-VideoTool.bat first, or:
    echo    1. Download from https://ffmpeg.org/download.html
    echo    2. Place ffmpeg.exe in: %~dp0
    echo    3. Or add FFmpeg to your system PATH
    echo.
    echo  The tool will attempt to run anyway...
    echo.
)

echo.

REM ---- Determine what to process ----
if "%~1"=="" (
    REM No arguments - interactive mode
    echo  USAGE OPTIONS:
    echo  ==============
    echo.
    echo  Option 1: Drag and drop video file(s) onto this .bat file
    echo.
    echo  Option 2: Run from command line:
    echo            VideoTool.bat "path\to\video.mp4"
    echo            VideoTool.bat "path\to\folder"
    echo            VideoTool.bat "path\to\video.mp4" "output\folder"
    echo.
    echo  Option 3: Enter path below (or press Enter to exit^)
    echo.
    echo  ============================================================
    echo.
    set /p "INPUT_PATH=  Enter video file or folder path: "

    if "!INPUT_PATH!"=="" (
        echo.
        echo  No input provided. Exiting.
        echo.
        echo  Press any key to close...
        pause >nul
        exit /b 0
    )

    echo.
    !PYTHON_CMD! "%~dp0videotool.py" !INPUT_PATH!
) else if "%~2"=="" (
    REM One argument - input file/folder only
    !PYTHON_CMD! "%~dp0videotool.py" "%~1"
) else (
    REM Two arguments - input and output
    !PYTHON_CMD! "%~dp0videotool.py" "%~1" "%~2"
)

if !errorlevel! neq 0 (
    echo.
    echo  ============================================================
    echo  VideoTool encountered an error. See messages above.
    echo  ============================================================
)

echo.
echo  ============================================================
echo  Press any key to close...
pause >nul
endlocal
exit /b 0
