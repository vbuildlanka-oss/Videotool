@echo off
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

REM Check for Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    where python3 >nul 2>nul
    if %errorlevel% neq 0 (
        echo  ERROR: Python is not installed or not in PATH.
        echo.
        echo  Please install Python 3.7+ from:
        echo    https://www.python.org/downloads/
        echo.
        echo  Make sure to check "Add Python to PATH" during installation.
        echo.
        pause
        exit /b 1
    )
    set PYTHON_CMD=python3
) else (
    set PYTHON_CMD=python
)

REM Check for FFmpeg
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%~dp0ffmpeg.exe" (
        echo  Found ffmpeg.exe in tool directory.
    ) else if exist "%~dp0ffmpeg\ffmpeg.exe" (
        echo  Found ffmpeg in subfolder.
    ) else (
        echo  WARNING: FFmpeg not found in PATH.
        echo.
        echo  FFmpeg is required. You can:
        echo    1. Download from https://ffmpeg.org/download.html
        echo    2. Place ffmpeg.exe in this folder: %~dp0
        echo    3. Or add FFmpeg to your system PATH
        echo.
        echo  The tool will attempt to run anyway...
        echo.
    )
)

REM Determine what to process
if "%~1"=="" (
    REM No arguments - show drag-and-drop instructions and interactive mode
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
    echo  Option 3: Enter path below
    echo.
    echo  ============================================================
    echo.
    set /p INPUT_PATH="  Enter video file or folder path: "

    if "!INPUT_PATH!"=="" (
        echo.
        echo  No input provided. Exiting.
        echo.
        pause
        exit /b 0
    )

    REM Enable delayed expansion for the interactive input
    setlocal enabledelayedexpansion
    %PYTHON_CMD% "%~dp0videotool.py" !INPUT_PATH!
    endlocal
) else if "%~2"=="" (
    REM One argument - input file/folder only
    %PYTHON_CMD% "%~dp0videotool.py" "%~1"
) else (
    REM Two arguments - input and output
    %PYTHON_CMD% "%~dp0videotool.py" "%~1" "%~2"
)

echo.
echo  ============================================================
echo  Press any key to close...
pause >nul
