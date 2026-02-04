#!/bin/bash
# Apply all patches to libDaisy

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIBDAISY_DIR="$SCRIPT_DIR/libDaisy"
PATCHES_DIR="$SCRIPT_DIR/patches"

echo "Applying libDaisy patches..."
echo ""

# Check if libDaisy directory exists
if [ ! -d "$LIBDAISY_DIR" ]; then
    echo "ERROR: libDaisy directory not found at $LIBDAISY_DIR"
    echo "Please ensure libDaisy is cloned in the project root"
    exit 1
fi

cd "$LIBDAISY_DIR"

# Apply ICM20948 fix
echo "Applying icm20948_fix.patch..."
if patch -p1 --dry-run < "$PATCHES_DIR/icm20948_fix.patch" > /dev/null 2>&1; then
    patch -p1 < "$PATCHES_DIR/icm20948_fix.patch"
    echo "✓ icm20948_fix.patch applied successfully"
elif grep -q "AuxillaryRegisterTransaction(true, slv_addr, reg_addr, 0)" src/dev/icm20948.h; then
    echo "✓ icm20948_fix.patch already applied (skipping)"
else
    echo "✗ icm20948_fix.patch failed to apply"
    echo "  The patch may already be applied or libDaisy may have changed"
    exit 1
fi

echo ""
echo "All patches applied successfully!"
echo ""
echo "Rebuilding libDaisy..."
make clean > /dev/null 2>&1
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo "✓ libDaisy patched and rebuilt successfully"
echo ""
echo "You can now compile the ICM20948 examples:"
echo "  cd examples"
echo "  make TARGET=imu_demo"
