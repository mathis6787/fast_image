# This script builds all native fast_image libraries for every supported platform.
# On macOS, Apple targets (iOS + macOS) must be built using the local SDK (cargo),
# while all other platforms (Android, Linux, Windows) are built using `cross`.
# 
# If you are developing locally on macOS and need to test or use non-macOS targets,
# ensure Docker is running, `cross` is installed, and run this script normally.

#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to the native directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NATIVE_DIR="$PROJECT_ROOT/native"

cd "$NATIVE_DIR"

echo -e "${GREEN}Building native libraries for all supported architectures (hybrid cross + cargo)...${NC}"

# Counter for success/failure
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

# Build function
# $1 = target triple
# $2 = description
# $3 = tool ("cross" or "cargo")
build_for_target() {
    local target=$1
    local description=$2
    local tool=$3

    TOTAL_COUNT=$((TOTAL_COUNT + 1))

    echo -e "${YELLOW}Building for $description (target: $target) using $tool${NC}"

    # Add the target if not already added
    rustup target add "$target" 2>/dev/null || true

    if [ "$tool" = "cross" ]; then
        if cross build --release --target "$target"; then
            echo -e "${GREEN}✓ Successfully built for $description with cross${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo -e "${RED}✗ Failed to build for $description with cross${NC}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        if cargo build --release --target "$target"; then
            echo -e "${GREEN}✓ Successfully built for $description with cargo${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo -e "${RED}✗ Failed to build for $description with cargo${NC}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi

    echo ""
}

# Android builds (use cross)
echo -e "${GREEN}=== Building Android libraries ===${NC}"
build_for_target "armv7-linux-androideabi" "Android ARM" "cross"
build_for_target "aarch64-linux-android" "Android ARM64" "cross"
build_for_target "i686-linux-android" "Android IA32" "cross"
# build_for_target "riscv64-linux-android" "Android RISC-V 64" "cross"
build_for_target "x86_64-linux-android" "Android x64" "cross"

# iOS builds (use cargo – cross cannot handle Apple SDKs)
echo -e "${GREEN}=== Building iOS libraries ===${NC}"
build_for_target "aarch64-apple-ios" "iOS ARM64 (Device)" "cargo"
build_for_target "aarch64-apple-ios-sim" "iOS ARM64 (Simulator)" "cargo"
build_for_target "x86_64-apple-ios" "iOS x64 (Simulator)" "cargo"

# Linux builds (use cross)
echo -e "${GREEN}=== Building Linux libraries ===${NC}"
build_for_target "armv7-unknown-linux-gnueabihf" "Linux ARM" "cross"
build_for_target "aarch64-unknown-linux-gnu" "Linux ARM64" "cross"
# build_for_target "i686-unknown-linux-gnu" "Linux IA32" "cross"
# build_for_target "riscv64gc-unknown-linux-gnu" "Linux RISC-V 64" "cross"
build_for_target "x86_64-unknown-linux-gnu" "Linux x64" "cross"

# macOS builds (use cargo – native toolchain)
echo -e "${GREEN}=== Building macOS libraries ===${NC}"
build_for_target "aarch64-apple-darwin" "macOS ARM64" "cargo"
build_for_target "x86_64-apple-darwin" "macOS x64" "cargo"

# Windows builds (use cross)
echo -e "${GREEN}=== Building Windows libraries ===${NC}"
build_for_target "aarch64-pc-windows-msvc" "Windows ARM64" "cross"
# build_for_target "i686-pc-windows-msvc" "Windows IA32" "cross"
build_for_target "x86_64-pc-windows-msvc" "Windows x64" "cross"

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Summary:${NC}"
echo -e "Total builds: $TOTAL_COUNT"
echo -e "${GREEN}Successful: $SUCCESS_COUNT${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    exit 1
else
    echo -e "${GREEN}All builds completed successfully!${NC}"
fi