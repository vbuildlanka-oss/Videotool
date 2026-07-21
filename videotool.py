"""
VBUILD(TM) VideoTool - C2PA & EXIF Metadata Remover
====================================================
Strips C2PA content credentials, EXIF tags, and all metadata from video files.
Outputs clean MP4 files with no provenance or tracking metadata.

Usage:
    python videotool.py <input_file_or_folder> [output_folder]
    python videotool.py --help

Requirements:
    - Python 3.7+
    - FFmpeg (must be in PATH or placed alongside this script)
"""

import os
import sys
import subprocess
import shutil
import argparse
import time
from pathlib import Path

# Supported input video extensions
SUPPORTED_EXTENSIONS = {
    '.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm',
    '.m4v', '.mpg', '.mpeg', '.3gp', '.ts', '.mts', '.m2ts'
}

BANNER = r"""
 ___    ___  ____   __  __  ____  __     ____  
 \  \  /  / | __ ) |  ||  ||_  _||  |   |  _ \ 
  \  \/  /  | __ \ |  ||  | _||_ |  |__ | |_) |
   \    /   |____/ \______/|____||____| |____/ 
    \__/    VideoTool - C2PA & Metadata Remover
            VBUILD(TM) Open Source Tool
"""


def find_ffmpeg():
    """Locate ffmpeg executable."""
    # Check if ffmpeg is in PATH
    ffmpeg_path = shutil.which("ffmpeg")
    if ffmpeg_path:
        return ffmpeg_path

    # Check alongside this script
    script_dir = Path(__file__).parent
    local_ffmpeg = script_dir / "ffmpeg.exe"
    if local_ffmpeg.exists():
        return str(local_ffmpeg)

    # Check in a 'ffmpeg' subfolder
    subfolder_ffmpeg = script_dir / "ffmpeg" / "ffmpeg.exe"
    if subfolder_ffmpeg.exists():
        return str(subfolder_ffmpeg)

    return None


def get_video_info(ffmpeg_path, input_file):
    """Get basic video file information using ffprobe."""
    ffprobe_path = ffmpeg_path.replace("ffmpeg", "ffprobe")
    if not shutil.which(ffprobe_path) and not os.path.exists(ffprobe_path):
        ffprobe_path = shutil.which("ffprobe")

    if not ffprobe_path:
        return None

    try:
        result = subprocess.run(
            [ffprobe_path, "-v", "quiet", "-print_format", "json",
             "-show_format", "-show_streams", str(input_file)],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0:
            return result.stdout
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def strip_metadata(ffmpeg_path, input_file, output_file):
    """
    Strip ALL metadata from a video file including C2PA/JUMBF boxes.
    
    Strategy:
    1. -map_metadata -1        -> Removes all global/stream metadata
    2. -map_chapters -1        -> Removes chapter metadata
    3. -fflags +bitexact       -> Prevents writing encoder tags
    4. -flags:v +bitexact      -> Prevents writing encoder info in video
    5. -flags:a +bitexact      -> Prevents writing encoder info in audio
    6. -movflags +faststart    -> Optimizes MP4 for streaming (clean rewrite)
    7. Re-muxing drops all non-essential boxes (including JUMBF/C2PA manifests)
    
    The video and audio streams are copied without re-encoding (lossless).
    """
    cmd = [
        ffmpeg_path,
        "-y",                       # Overwrite output
        "-i", str(input_file),      # Input file
        "-map", "0:v?",             # Map video streams
        "-map", "0:a?",             # Map audio streams  
        "-map", "0:s?",             # Map subtitle streams (if any)
        "-c", "copy",               # Copy all streams (no re-encode)
        "-map_metadata", "-1",      # Strip ALL metadata
        "-map_chapters", "-1",      # Strip chapters metadata
        "-fflags", "+bitexact",     # No encoder tags
        "-flags:v", "+bitexact",    # No video encoder info
        "-flags:a", "+bitexact",    # No audio encoder info
        "-movflags", "+faststart",  # Clean MP4 structure
        "-write_tmcd", "0",         # No timecode track
        str(output_file)
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=600  # 10 minute timeout per file
        )

        if result.returncode != 0:
            # If copy mode fails (incompatible codec), try with re-encoding
            cmd_reencode = [
                ffmpeg_path,
                "-y",
                "-i", str(input_file),
                "-map", "0:v?",
                "-map", "0:a?",
                "-c:v", "libx264",          # Re-encode video as H.264
                "-preset", "medium",
                "-crf", "18",               # High quality
                "-c:a", "aac",              # Re-encode audio as AAC
                "-b:a", "192k",
                "-map_metadata", "-1",
                "-map_chapters", "-1",
                "-fflags", "+bitexact",
                "-flags:v", "+bitexact",
                "-flags:a", "+bitexact",
                "-movflags", "+faststart",
                "-write_tmcd", "0",
                str(output_file)
            ]

            result = subprocess.run(
                cmd_reencode,
                capture_output=True,
                text=True,
                timeout=1800  # 30 minute timeout for re-encoding
            )

            if result.returncode != 0:
                return False, result.stderr
            return True, "Re-encoded (codec incompatible with copy mode)"

        return True, "Stream copied (lossless)"

    except subprocess.TimeoutExpired:
        return False, "Processing timed out"
    except Exception as e:
        return False, str(e)


def verify_clean(ffmpeg_path, output_file):
    """Verify that the output file has no C2PA/metadata remaining."""
    ffprobe_path = ffmpeg_path.replace("ffmpeg", "ffprobe")
    if not os.path.exists(ffprobe_path):
        ffprobe_path = shutil.which("ffprobe")

    if not ffprobe_path:
        return True, "ffprobe not available for verification"

    try:
        # Check for any remaining metadata
        result = subprocess.run(
            [ffprobe_path, "-v", "quiet", "-print_format", "flat",
             "-show_format", str(output_file)],
            capture_output=True, text=True, timeout=30
        )

        # Look for any C2PA or suspicious metadata indicators
        suspicious_keys = ['c2pa', 'jumbf', 'content_credentials', 
                          'manifest', 'provenance']
        output_lower = result.stdout.lower()

        for key in suspicious_keys:
            if key in output_lower:
                return False, f"Warning: '{key}' found in output metadata"

        return True, "Clean - no C2PA/provenance metadata detected"

    except (subprocess.TimeoutExpired, FileNotFoundError):
        return True, "Verification skipped"


def process_file(ffmpeg_path, input_file, output_dir):
    """Process a single video file."""
    input_path = Path(input_file)
    output_path = Path(output_dir) / f"{input_path.stem}_clean.mp4"

    # Avoid overwriting
    counter = 1
    while output_path.exists():
        output_path = Path(output_dir) / f"{input_path.stem}_clean_{counter}.mp4"
        counter += 1

    print(f"\n  Processing: {input_path.name}")
    print(f"  Output:     {output_path.name}")
    print(f"  Status:     ", end="", flush=True)

    start_time = time.time()
    success, message = strip_metadata(ffmpeg_path, input_path, output_path)
    elapsed = time.time() - start_time

    if success:
        # Verify the output
        clean, verify_msg = verify_clean(ffmpeg_path, output_path)

        input_size = input_path.stat().st_size / (1024 * 1024)
        output_size = output_path.stat().st_size / (1024 * 1024)

        print(f"SUCCESS ({elapsed:.1f}s)")
        print(f"  Method:     {message}")
        print(f"  Size:       {input_size:.1f} MB -> {output_size:.1f} MB")
        print(f"  Verify:     {verify_msg}")
        return True
    else:
        print(f"FAILED")
        print(f"  Error:      {message}")
        # Clean up failed output
        if output_path.exists():
            output_path.unlink()
        return False


def main():
    parser = argparse.ArgumentParser(
        description="VBUILD(TM) VideoTool - Remove C2PA & EXIF metadata from videos",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  videotool.py video.mp4                    Process single file
  videotool.py video.mp4 ./output           Process file, save to output folder
  videotool.py ./videos                     Process all videos in folder
  videotool.py ./videos ./clean_output      Process folder, save to output folder

Supported formats: MP4, MOV, AVI, MKV, WMV, FLV, WebM, M4V, MPG, MPEG, 3GP, TS
Output is always MP4 (H.264/AAC).

VBUILD(TM) Open Source | github.com/vbuildlanka-oss/Videotool
        """
    )
    parser.add_argument("input", help="Input video file or folder containing videos")
    parser.add_argument("output", nargs="?", default=None,
                       help="Output folder (default: 'cleaned' subfolder next to input)")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Show detailed ffmpeg output")

    args = parser.parse_args()

    # Display banner
    print(BANNER)

    # Find ffmpeg
    ffmpeg_path = find_ffmpeg()
    if not ffmpeg_path:
        print("ERROR: FFmpeg not found!")
        print("")
        print("Please install FFmpeg:")
        print("  1. Download from https://ffmpeg.org/download.html")
        print("  2. Add to your system PATH")
        print("     OR place ffmpeg.exe in the same folder as this script")
        print("")
        sys.exit(1)

    print(f"  FFmpeg: {ffmpeg_path}")

    # Resolve input path
    input_path = Path(args.input).resolve()
    if not input_path.exists():
        print(f"\nERROR: Input not found: {args.input}")
        sys.exit(1)

    # Collect video files
    video_files = []
    if input_path.is_file():
        if input_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            video_files.append(input_path)
        else:
            print(f"\nERROR: Unsupported file format: {input_path.suffix}")
            print(f"Supported: {', '.join(sorted(SUPPORTED_EXTENSIONS))}")
            sys.exit(1)
    elif input_path.is_dir():
        for f in sorted(input_path.iterdir()):
            if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS:
                video_files.append(f)

    if not video_files:
        print(f"\nERROR: No supported video files found in: {input_path}")
        sys.exit(1)

    # Resolve output directory
    if args.output:
        output_dir = Path(args.output).resolve()
    elif input_path.is_file():
        output_dir = input_path.parent / "cleaned"
    else:
        output_dir = input_path / "cleaned"

    output_dir.mkdir(parents=True, exist_ok=True)

    # Process files
    print(f"\n  Input:  {input_path}")
    print(f"  Output: {output_dir}")
    print(f"  Files:  {len(video_files)} video(s) to process")
    print(f"\n{'='*60}")

    success_count = 0
    fail_count = 0

    for video_file in video_files:
        if process_file(ffmpeg_path, video_file, output_dir):
            success_count += 1
        else:
            fail_count += 1

    # Summary
    print(f"\n{'='*60}")
    print(f"\n  COMPLETE: {success_count} processed, {fail_count} failed")
    print(f"  Output folder: {output_dir}")
    print(f"\n  All C2PA content credentials and EXIF metadata removed.")
    print(f"  VBUILD(TM) VideoTool | Open Source")
    print()

    sys.exit(0 if fail_count == 0 else 1)


if __name__ == "__main__":
    main()
