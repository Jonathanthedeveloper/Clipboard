#!/bin/bash

APP_NAME="Clipboard"
DMG_NAME="Clipboard.dmg"
SOURCE_APP="./$APP_NAME.app"

# Check if the app exists in the current directory
if [ ! -d "$SOURCE_APP" ]; then
    echo "Error: $APP_NAME.app not found in the current directory."
    echo "   Please Archive the app in Xcode, Export it as 'Copy App', and save it here."
    exit 1
fi

# Create a temporary folder for the DMG content
echo "Preparing DMG contents..."
rm -rf "dmg_temp"
mkdir "dmg_temp"
cp -r "$SOURCE_APP" "dmg_temp/"
ln -s /Applications "dmg_temp/Applications"

# Create the DMG
echo "Creating $DMG_NAME..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "dmg_temp" -ov -format UDZO "$DMG_NAME"

# Cleanup
rm -rf "dmg_temp"

echo "Done! $DMG_NAME created successfully."
