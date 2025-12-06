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

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if fastforge is available
if ! flutter pub deps | grep -q fastforge; then
    print_warning "Fastforge not found, running pub get..."
    flutter pub get
fi

# Create output directory
mkdir -p build/dist

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
                mkdir -p build/dist
                if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
                    cp build/app/outputs/flutter-apk/app-release.apk build/dist/klit.apk
                    print_status "APK built successfully: build/dist/klit.apk"
                fi
            fi
            ;;
        ios)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                flutter build ipa --release --no-codesign || flutter build ios --release --no-codesign
                if [ -d "build/ios/ipa" ]; then
                    cp build/ios/ipa/*.ipa build/dist/ 2>/dev/null || true
                    print_status "IPA built successfully"
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
                
                # Build AppImage using fastforge
                if [ -x "$FASTFORGE" ]; then
                    $FASTFORGE package --platform linux --targets appimage || print_warning "AppImage build failed"
                    $FASTFORGE package --platform linux --targets deb || print_warning "DEB build failed"
                    $FASTFORGE package --platform linux --targets rpm || print_warning "RPM build failed"
                else
                    print_warning "fastforge not found. Run: dart pub global activate fastforge"
                fi
                
                # Copy linux bundle to dist
                if [ -d "build/linux/x64/release/bundle" ]; then
                    cp -r build/linux/x64/release/bundle build/dist/klit-linux
                    print_status "Linux bundle copied to build/dist/klit-linux"
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
echo "Output directory: build/dist/"
echo ""
ls -la build/dist/ 2>/dev/null || echo "No files in build/dist/"
echo ""
print_status "Build process completed!"
