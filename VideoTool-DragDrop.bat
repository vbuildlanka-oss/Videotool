@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  VBUILD(TM) VideoTool - Drag & Drop Mode
REM  Simply drag video files or a folder onto this .bat file
REM  to strip all C2PA and EXIF metadata.
REM  Output goes to a "cleaned" subfolder next to the input.
REM ============================================================

title VBUILD VideoTool - Drag and Drop Processing

echo.
echo  VBUILD(TM) VideoTool - Drag ^& Drop Mode
echo  =========================================
echo.

REM ---- Locate Python ----
set "PYTHON_CMD="

where python >nul 2>nul
if !errorlevel! equ 0 (
    python --version >nul 2>nul
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=python"
        goto :py_ok
    )
)

where python3 >nul 2>nul
if !errorlevel! equ 0 (
    set "PYTHON_CMD=python3"
    goto :py_ok
)

if exist "C:\Python312\python.exe" (
    set "PYTHON_CMD=C:\Python312\python.exe"
    goto :py_ok
)
if exist "C:\Python311\python.exe" (
    set "PYTHON_CMD=C:\Python311\python.exe"
    goto :py_ok
)
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    goto :py_ok
)
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto :py_ok
)

echo  ERROR: Python is not installed or not in PATH.
echo.
echo  Please run Install-VideoTool.bat first, or install Python manually:
echo    https://www.python.org/downloads/
echo.
echo  Press any key to exit...
pause >nul
exit /b 1

:py_ok

REM ---- Add local ffmpeg to PATH if present ----
if exist "%~dp0ffmpeg.exe" (
    set "PATH=%~dp0;!PATH!"
) else if exist "%~dp0ffmpeg\ffmpeg.exe" (
    set "PATH=%~dp0ffmpeg;!PATH!"
) else if exist "%~dp0ffmpeg\bin\ffmpeg.exe" (
    set "PATH=%~dp0ffmpeg\bin;!PATH!"
)

REM ---- Process dragged files ----
if "%~1"=="" (
    echo  No files were provided!
    echo.
    echo  HOW TO USE:
    echo  Drag one or more video files (or a folder^) onto this .bat file.
    echo  The cleaned videos will be saved to a "cleaned" subfolder.
    echo.
    echo  Press any key to close...
    pause >nul
    exit /b 0
)

set "COUNT=0"
set "ERRORS=0"

for %%F in (%*) do (
    set /a COUNT+=1
    echo  [!COUNT!] Processing: %%~nxF
    !PYTHON_CMD! "%~dp0videotool.py" "%%~F"
    if !errorlevel! neq 0 (
        set /a ERRORS+=1
    )
)

echo.
echo  =========================================
echo  Done! Processed !COUNT! item(s), !ERRORS! error(s).
echo  =========================================
echo.
echo  Press any key to close...
pause >nul
endlocal
exit /b 0
