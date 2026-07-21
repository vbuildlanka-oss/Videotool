@echo off
REM ============================================================
REM  VBUILD(TM) VideoTool - Drag & Drop Mode
REM  Simply drag video files or a folder onto this .bat file
REM  to strip all C2PA and EXIF metadata.
REM  Output goes to a "cleaned" subfolder next to the input.
REM ============================================================

title VBUILD VideoTool - Processing...

setlocal enabledelayedexpansion

REM Check for Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH.
    echo Please install Python 3.7+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Process all dragged files/folders
set COUNT=0
for %%F in (%*) do (
    set /a COUNT+=1
    echo.
    echo Processing item !COUNT!: %%~F
    python "%~dp0videotool.py" "%%~F"
)

if %COUNT%==0 (
    echo.
    echo  No files were provided.
    echo  Drag video files or a folder onto this .bat file to process them.
    echo.
)

echo.
echo Done! Press any key to close...
pause >nul
