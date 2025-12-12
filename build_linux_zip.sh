#!/bin/bash

# --- Script for Local Flutter Linux Release Build and Zip Creation ---

# 1. Set the name for the final zip file
ZIP_FILENAME="klit-linux-x64.zip"
# 2. Set the build folder path (where Flutter puts the compiled files)
BUILD_DIR="build/linux/x64/release"

echo "Starting Flutter Linux release build..."

# --- 3. Check for required tools ---
if ! command -v flutter &> /dev/null
then
    echo "ERROR: 'flutter' command not found."
    echo "Please make sure Flutter is installed and in your PATH."
    exit 1
fi

if ! command -v zip &> /dev/null
then
    echo "ERROR: 'zip' command not found."
    echo "Please install it (e.g., 'sudo apt install zip')."
    exit 1
fi

# --- 4. Setup and Clean ---
echo "Running flutter pub get..."
flutter pub get

echo "Enabling Linux desktop support..."
flutter config --enable-linux-desktop

# Clean up previous build directories for a fresh start
echo "Cleaning up previous build files..."
rm -rf "$BUILD_DIR"
rm -f "$ZIP_FILENAME"

# --- 5. Build the application ---
echo "Building Flutter application for Linux (release mode)..."
# We use a simple timestamp as a dummy build number, as $CI_PIPELINE_ID isn't available locally
BUILD_NUMBER=$(date +%s)
flutter build linux --release --build-number="$BUILD_NUMBER"

# Check if the build was successful
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter build failed."
    exit 1
fi

# --- 6. Create the Zip Archive ---
echo "Build complete. Creating zip file: $ZIP_FILENAME"

# Check if the bundle directory exists after the build
if [ ! -d "$BUILD_DIR/bundle" ]; then
    echo "ERROR: The expected build directory '$BUILD_DIR/bundle' was not found."
    exit 1
fi

# Go into the release directory and zip the 'bundle' folder
cd "$BUILD_DIR" || exit 1
zip -r "../../..//$ZIP_FILENAME" bundle/ > /dev/null

# Go back to the original project directory
cd "$OLDPWD"

# --- 7. Done ---
echo "--------------------------------"
echo "✅ SUCCESS! Linux release build and zip created."
echo "Zip file location: $PWD/$ZIP_FILENAME"
echo "--------------------------------"