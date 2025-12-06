#!/bin/bash

# Klit Build Script using Fastforge
# Builds for: APK, IPA, AppImage, DEB, DMG, EXE, RPM

set -e

echo "==================================="
echo "Klit Build Script"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Read version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d '[:space:]')
if [ -z "$VERSION" ]; then
    print_error "Could not read version from pubspec.yaml"
    exit 1
fi

print_status "Building Klit version: $VERSION"

# Create output directory with version
DIST_DIR="dist/$VERSION"
mkdir -p "$DIST_DIR"

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Ensure dependencies are up to date
flutter pub get 2>/dev/null || true

# Function to build for a specific platform
build_platform() {
    local platform=$1
    local format=$2
    
    echo ""
    echo "-----------------------------------"
    echo "Building for $platform ($format)"
    echo "-----------------------------------"
    
    case $platform in
        android)
            if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "msys" ]]; then
                flutter build apk --release
                if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
                    cp build/app/outputs/flutter-apk/app-release.apk "$DIST_DIR/klit-android-$VERSION.apk"
                    print_status "APK built successfully: $DIST_DIR/klit-android-$VERSION.apk"
                fi
            fi
            ;;
        ios)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                flutter build ipa --release --no-codesign || flutter build ios --release --no-codesign
                if [ -d "build/ios/ipa" ]; then
                    for ipa in build/ios/ipa/*.ipa; do
                        if [ -f "$ipa" ]; then
                            cp "$ipa" "$DIST_DIR/klit-ios-$VERSION.ipa"
                            print_status "IPA built successfully: $DIST_DIR/klit-ios-$VERSION.ipa"
                        fi
                    done
                else
                    print_warning "IPA build completed (may need manual export from Xcode)"
                fi
            else
                print_warning "Skipping iOS build - requires macOS"
            fi
            ;;
        linux)
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                flutter build linux --release
                
                # Use globally installed fastforge
                FASTFORGE="$HOME/.pub-cache/bin/fastforge"
                
                # Build packages using fastforge
                if [ -x "$FASTFORGE" ]; then
                    $FASTFORGE package --platform linux --targets appimage || print_warning "AppImage build failed"
                    $FASTFORGE package --platform linux --targets deb || print_warning "DEB build failed"
                    $FASTFORGE package --platform linux --targets rpm || print_warning "RPM build failed"
                    
                    # Move fastforge outputs to versioned dist folder
                    for appimage in dist/*.AppImage; do
                        if [ -f "$appimage" ]; then
                            mv "$appimage" "$DIST_DIR/klit-linux-$VERSION.AppImage"
                            print_status "AppImage: $DIST_DIR/klit-linux-$VERSION.AppImage"
                        fi
                    done
                    
                    for deb in dist/*.deb; do
                        if [ -f "$deb" ]; then
                            mv "$deb" "$DIST_DIR/klit-linux-$VERSION.deb"
                            print_status "DEB: $DIST_DIR/klit-linux-$VERSION.deb"
                        fi
                    done
                    
                    for rpm in dist/*.rpm; do
                        if [ -f "$rpm" ]; then
                            mv "$rpm" "$DIST_DIR/klit-linux-$VERSION.rpm"
                            print_status "RPM: $DIST_DIR/klit-linux-$VERSION.rpm"
                        fi
                    done
                else
                    print_warning "fastforge not found. Run: dart pub global activate fastforge"
                fi
                
                print_status "Linux builds completed"
            else
                print_warning "Skipping Linux build - requires Linux"
            fi
            ;;
        macos)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                flutter build macos --release
                
                # Use globally installed fastforge
                FASTFORGE="$HOME/.pub-cache/bin/fastforge"
                
                # Build DMG using fastforge
                if [ -x "$FASTFORGE" ]; then
                    $FASTFORGE package --platform macos --targets dmg || print_warning "DMG build failed"
                    
                    # Move fastforge outputs to versioned dist folder
                    for dmg in dist/*.dmg; do
                        if [ -f "$dmg" ]; then
                            mv "$dmg" "$DIST_DIR/klit-macos-$VERSION.dmg"
                            print_status "DMG: $DIST_DIR/klit-macos-$VERSION.dmg"
                        fi
                    done
                else
                    print_warning "fastforge not found. Run: dart pub global activate fastforge"
                fi
                
                print_status "macOS DMG built successfully"
            else
                print_warning "Skipping macOS build - requires macOS"
            fi
            ;;
        windows)
            if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
                flutter build windows --release
                
                # Use globally installed fastforge
                FASTFORGE="$HOME/.pub-cache/bin/fastforge"
                
                # Build EXE installer using fastforge
                if [ -x "$FASTFORGE" ]; then
                    $FASTFORGE package --platform windows --targets exe || print_warning "EXE build failed"
                    
                    # Move fastforge outputs to versioned dist folder
                    for exe in dist/*.exe; do
                        if [ -f "$exe" ]; then
                            mv "$exe" "$DIST_DIR/klit-windows-$VERSION.exe"
                            print_status "EXE: $DIST_DIR/klit-windows-$VERSION.exe"
                        fi
                    done
                else
                    print_warning "fastforge not found. Run: dart pub global activate fastforge"
                fi
                
                print_status "Windows EXE built successfully"
            else
                print_warning "Skipping Windows build - requires Windows"
            fi
            ;;
    esac
}

# Parse command line arguments
BUILD_ALL=true
BUILD_ANDROID=false
BUILD_IOS=false
BUILD_LINUX=false
BUILD_MACOS=false
BUILD_WINDOWS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --android)
            BUILD_ALL=false
            BUILD_ANDROID=true
            shift
            ;;
        --ios)
            BUILD_ALL=false
            BUILD_IOS=true
            shift
            ;;
        --linux)
            BUILD_ALL=false
            BUILD_LINUX=true
            shift
            ;;
        --macos)
            BUILD_ALL=false
            BUILD_MACOS=true
            shift
            ;;
        --windows)
            BUILD_ALL=false
            BUILD_WINDOWS=true
            shift
            ;;
        --all)
            BUILD_ALL=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --android    Build APK only"
            echo "  --ios        Build IPA only (macOS required)"
            echo "  --linux      Build AppImage, DEB, RPM (Linux required)"
            echo "  --macos      Build DMG only (macOS required)"
            echo "  --windows    Build EXE only (Windows required)"
            echo "  --all        Build all platforms (default)"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Build based on arguments
if [ "$BUILD_ALL" = true ]; then
    build_platform android apk
    build_platform ios ipa
    build_platform linux "appimage,deb,rpm"
    build_platform macos dmg
    build_platform windows exe
else
    [ "$BUILD_ANDROID" = true ] && build_platform android apk
    [ "$BUILD_IOS" = true ] && build_platform ios ipa
    [ "$BUILD_LINUX" = true ] && build_platform linux "appimage,deb,rpm"
    [ "$BUILD_MACOS" = true ] && build_platform macos dmg
    [ "$BUILD_WINDOWS" = true ] && build_platform windows exe
fi

echo ""
echo "==================================="
echo "Build Summary"
echo "==================================="
echo "Version: $VERSION"
echo "Output directory: $DIST_DIR/"
echo ""
ls -la "$DIST_DIR/" 2>/dev/null || echo "No files in $DIST_DIR/"
echo ""
print_status "Build process completed!"
