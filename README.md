# VBUILD™ VideoTool

**C2PA & EXIF Metadata Remover for Video Files**

A lightweight, local tool that strips C2PA content credentials, EXIF tags, and all embedded metadata from video files. Outputs clean MP4 files with zero provenance or tracking metadata.

---

## What It Does

- **Removes C2PA manifests** (Content Credentials / JUMBF boxes)
- **Strips all EXIF metadata** (camera info, GPS, timestamps, etc.)
- **Clears encoder tags** and chapter metadata
- **Outputs clean MP4** with H.264 video and AAC audio
- **Lossless by default** — copies streams without re-encoding when possible
- **Batch processing** — process entire folders of videos at once
- **Verification** — confirms output files are metadata-free

---

## Installation

### Automatic Installer (Recommended)

1. Download or clone this repository
2. **Right-click `Install-VideoTool.bat`** → **Run as administrator**
3. The installer will automatically:
   - Download and install Python 3.12 (if not already installed)
   - Download and install FFmpeg (if not already installed)
   - Add both to your system PATH
   - Verify all VideoTool files are present
   - Create Desktop shortcuts for easy access
4. Done! Start using VideoTool immediately.

> **Tip:** Running as Administrator ensures Python and FFmpeg can be added to the system PATH properly.

### Manual Installation

If you prefer to install dependencies yourself:

| Requirement | Details |
|-------------|---------|
| **OS** | Windows 7/8/10/11 |
| **Python** | 3.7 or newer ([Download](https://www.python.org/downloads/)) |
| **FFmpeg** | Any recent version ([Download](https://ffmpeg.org/download.html)) |

> **Note:** When installing Python, make sure to check **"Add Python to PATH"**.

#### FFmpeg Installation Options

1. **Add to system PATH** (recommended) — Install FFmpeg and add its `bin` folder to your PATH
2. **Place alongside the tool** — Put `ffmpeg.exe` in the same folder as `VideoTool.bat`
3. **Subfolder** — Put FFmpeg files in a `ffmpeg/` subfolder

---

## Quick Start

### Option 1: Drag & Drop

1. Drag a video file (or a folder of videos) onto **`VideoTool-DragDrop.bat`**
2. Cleaned files appear in a `cleaned/` subfolder

### Option 2: Double-Click Interactive Mode

1. Double-click **`VideoTool.bat`**
2. Enter the path to your video file or folder when prompted
3. Cleaned files appear in a `cleaned/` subfolder

### Option 3: Command Line

```batch
REM Process a single file
VideoTool.bat "C:\Videos\my_video.mp4"

REM Process a folder
VideoTool.bat "C:\Videos\raw_footage"

REM Process with custom output folder
VideoTool.bat "C:\Videos\my_video.mp4" "C:\Videos\output"
```

### Option 4: Python Directly

```bash
python videotool.py input_video.mp4
python videotool.py ./video_folder
python videotool.py input_video.mp4 ./output_folder
```

---

## Supported Input Formats

| Format | Extensions |
|--------|-----------|
| MPEG-4 | `.mp4`, `.m4v` |
| QuickTime | `.mov` |
| AVI | `.avi` |
| Matroska | `.mkv` |
| Windows Media | `.wmv` |
| Flash Video | `.flv` |
| WebM | `.webm` |
| MPEG | `.mpg`, `.mpeg` |
| 3GPP | `.3gp` |
| Transport Stream | `.ts`, `.mts`, `.m2ts` |

**Output is always MP4** (`.mp4`).

---

## How It Works

1. **Stream Copy Mode (Lossless):** The tool copies video/audio streams directly into a new MP4 container, stripping all metadata boxes including C2PA/JUMBF manifests. No quality loss occurs.

2. **Re-encode Fallback:** If the source codec is incompatible with MP4 (rare), the tool automatically re-encodes using H.264 (CRF 18, high quality) and AAC audio (192kbps).

3. **Verification:** After processing, the tool checks the output file to confirm no C2PA or provenance metadata remains.

### What Gets Removed

| Metadata Type | Removed? |
|--------------|----------|
| C2PA Manifests (JUMBF) | ✅ |
| EXIF Data | ✅ |
| XMP Metadata | ✅ |
| GPS/Location Data | ✅ |
| Camera/Device Info | ✅ |
| Encoder Information | ✅ |
| Chapter Markers | ✅ |
| Timecode Tracks | ✅ |
| Custom MP4 Boxes | ✅ |

---

## File Structure

```
Videotool/
├── Install-VideoTool.bat    # One-click installer (run first!)
├── VideoTool.bat            # Main launcher (interactive + CLI)
├── VideoTool-DragDrop.bat   # Drag-and-drop launcher
├── videotool.py             # Core Python processing script
└── README.md                # This file
```

---

## Example Output

```
 ___    ___  ____   __  __  ____  __     ____
 \  \  /  / | __ ) |  ||  ||_  _||  |   |  _ \
  \  \/  /  | __ \ |  ||  | _||_ |  |__ | |_) |
   \    /   |____/ \______/|____||____| |____/
    \__/    VideoTool - C2PA & Metadata Remover
            VBUILD(TM) Open Source Tool

  FFmpeg: C:\ffmpeg\bin\ffmpeg.exe

  Input:  C:\Videos\raw_footage
  Output: C:\Videos\raw_footage\cleaned
  Files:  3 video(s) to process

============================================================

  Processing: interview_clip.mp4
  Output:     interview_clip_clean.mp4
  Status:     SUCCESS (2.3s)
  Method:     Stream copied (lossless)
  Size:       245.6 MB -> 245.1 MB
  Verify:     Clean - no C2PA/provenance metadata detected

============================================================

  COMPLETE: 3 processed, 0 failed
  Output folder: C:\Videos\raw_footage\cleaned
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Python is not installed" | Install Python 3.7+ and check "Add to PATH" |
| "FFmpeg not found" | Download FFmpeg and add to PATH or place in tool folder |
| File fails with copy mode | Automatic — tool re-encodes with H.264/AAC |
| Output file is larger | Normal for some codecs when re-encoding is needed |

---

## License

Open source. Free to use, modify, and distribute.

---

## Credits

**VBUILD™** Open Source | [github.com/vbuildlanka-oss/Videotool](https://github.com/vbuildlanka-oss/Videotool)
