#!/usr/bin/env bash
set -euo pipefail

SRC="logo.png"
WORK="icon_work"
MASTER="$WORK/master-1024.png"

if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC in current directory"; exit 1
fi

rm -rf "$WORK" AppIcon.appiconset MyIcon.iconset MyIcon.icns
mkdir -p "$WORK"

echo "1) Crop to centered square and make 1024x1024 master…"
# Crop to min dimension (1837) centered, then downscale to 1024
# sips will auto-center if we give cropToHeightWidth and start with square target
sips "$SRC" --cropToHeightWidth 1837 1837 --out "$WORK/cropped.png" >/dev/null
sips -Z 1024 "$WORK/cropped.png" --out "$MASTER" >/dev/null

# Helper to resize from master
gen() { # gen <size> <outfile>
  sips -Z "$1" "$MASTER" --out "$2" >/dev/null
}

############################################
# A) macOS .icns (for widget extension icon)
############################################
echo "2) Build macOS .icns…"
mkdir -p MyIcon.iconset
gen 16   MyIcon.iconset/icon_16x16.png
gen 32   MyIcon.iconset/icon_16x16@2x.png
gen 32   MyIcon.iconset/icon_32x32.png
gen 64   MyIcon.iconset/icon_32x32@2x.png
gen 128  MyIcon.iconset/icon_128x128.png
gen 256  MyIcon.iconset/icon_128x128@2x.png
gen 256  MyIcon.iconset/icon_256x256.png
gen 512  MyIcon.iconset/icon_256x256@2x.png
gen 512  MyIcon.iconset/icon_512x512.png
cp "$MASTER" MyIcon.iconset/icon_512x512@2x.png  # 1024

iconutil -c icns -o 3dg.icns MyIcon.iconset
cp 3dg.icns 3dg.icons
echo "  -> 3dg.icns and 3dg.icons"

######################################################
# B) iOS/iPadOS AppIcon.appiconset for Widget extension
######################################################
echo "3) Build iOS/iPadOS AppIcon.appiconset…"
mkdir -p AppIcon.appiconset

# iPhone
gen 40   AppIcon.appiconset/Icon-20@2x.png      # 20pt @2x
gen 60   AppIcon.appiconset/Icon-20@3x.png      # 20pt @3x
gen 58   AppIcon.appiconset/Icon-29@2x.png      # 29pt @2x
gen 87   AppIcon.appiconset/Icon-29@3x.png      # 29pt @3x
gen 80   AppIcon.appiconset/Icon-40@2x.png      # 40pt @2x
gen 120  AppIcon.appiconset/Icon-40@3x.png      # 40pt @3x
gen 120  AppIcon.appiconset/Icon-60@2x.png      # 60pt @2x
gen 180  AppIcon.appiconset/Icon-60@3x.png      # 60pt @3x

# iPad
gen 20   AppIcon.appiconset/Icon-20.png         # 20pt @1x
gen 40   AppIcon.appiconset/Icon-20@2x-ipad.png # 20pt @2x
gen 29   AppIcon.appiconset/Icon-29.png         # 29pt @1x
gen 58   AppIcon.appiconset/Icon-29@2x-ipad.png # 29pt @2x
gen 40   AppIcon.appiconset/Icon-40.png         # 40pt @1x
gen 80   AppIcon.appiconset/Icon-40@2x-ipad.png # 40pt @2x
gen 76   AppIcon.appiconset/Icon-76.png         # 76pt @1x
gen 152  AppIcon.appiconset/Icon-76@2x.png      # 76pt @2x
gen 167  AppIcon.appiconset/Icon-83.5@2x.png    # 83.5pt @2x

# App Store
cp "$MASTER" AppIcon.appiconset/Icon-1024.png   # 1024×1024

# Contents.json (covers the above)
cat > AppIcon.appiconset/Contents.json <<'JSON'
{
  "images": [
    { "idiom": "iphone", "size": "20x20",  "scale": "2x", "filename": "Icon-20@2x.png" },
    { "idiom": "iphone", "size": "20x20",  "scale": "3x", "filename": "Icon-20@3x.png" },
    { "idiom": "iphone", "size": "29x29",  "scale": "2x", "filename": "Icon-29@2x.png" },
    { "idiom": "iphone", "size": "29x29",  "scale": "3x", "filename": "Icon-29@3x.png" },
    { "idiom": "iphone", "size": "40x40",  "scale": "2x", "filename": "Icon-40@2x.png" },
    { "idiom": "iphone", "size": "40x40",  "scale": "3x", "filename": "Icon-40@3x.png" },
    { "idiom": "iphone", "size": "60x60",  "scale": "2x", "filename": "Icon-60@2x.png" },
    { "idiom": "iphone", "size": "60x60",  "scale": "3x", "filename": "Icon-60@3x.png" },

    { "idiom": "ipad",   "size": "20x20",  "scale": "1x", "filename": "Icon-20.png" },
    { "idiom": "ipad",   "size": "20x20",  "scale": "2x", "filename": "Icon-20@2x-ipad.png" },
    { "idiom": "ipad",   "size": "29x29",  "scale": "1x", "filename": "Icon-29.png" },
    { "idiom": "ipad",   "size": "29x29",  "scale": "2x", "filename": "Icon-29@2x-ipad.png" },
    { "idiom": "ipad",   "size": "40x40",  "scale": "1x", "filename": "Icon-40.png" },
    { "idiom": "ipad",   "size": "40x40",  "scale": "2x", "filename": "Icon-40@2x-ipad.png" },
    { "idiom": "ipad",   "size": "76x76",  "scale": "1x", "filename": "Icon-76.png" },
    { "idiom": "ipad",   "size": "76x76",  "scale": "2x", "filename": "Icon-76@2x.png" },
    { "idiom": "ipad",   "size": "83.5x83.5", "scale": "2x", "filename": "Icon-83.5@2x.png" },

    { "idiom": "ios-marketing", "size": "1024x1024", "scale": "1x", "filename": "Icon-1024.png" }
  ],
  "info": { "version": 1, "author": "xcode" }
}
JSON

echo "Done."
echo " - macOS icns: MyIcon.icns"
echo " - iOS/iPadOS asset catalog: AppIcon.appiconset/ (drop into your Widget extension)"