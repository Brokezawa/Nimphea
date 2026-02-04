# LibDaisy Patches

This directory contains patches for bugs in the upstream libDaisy library that affect Nimphea.

## Why Patches Are Needed

While we work with the libDaisy team to get fixes merged upstream, we maintain local patches to ensure all sensor modules work correctly with Nimphea.

## Current Patches

### icm20948_fix.patch

**Status**: Prepared for upstream submission  
**Affects**: ICM20948 9-axis IMU sensor  
**Issue**: Function argument count mismatch in magnetometer operations

**Problem**:
The `ReadExternalRegister()` function in `libDaisy/src/dev/icm20948.h` calls `AuxillaryRegisterTransaction()` with 3 arguments, but the function signature expects 4 arguments. This causes compilation errors when using magnetometer functionality (SetupMag, GetMagId, ReadMagRegister).

**Fix**:
Pass `0` as the 4th argument for read operations. The `value` parameter is only used for write operations, so passing 0 for reads is safe and correct.

**Changed Line** (line 686):
```cpp
// Before (broken):
return AuxillaryRegisterTransaction(true, slv_addr, reg_addr);

// After (fixed):
return AuxillaryRegisterTransaction(true, slv_addr, reg_addr, 0);
```

**Impact Without Patch**:
- NO: Cannot compile examples using ICM20948
- NO: Cannot initialize magnetometer
- NO: Cannot read magnetic field data
- YES: Accelerometer and gyroscope still work (don't use this function)

**Impact With Patch**:
- YES: Full 9-axis IMU functionality (accel + gyro + mag)
- YES: All ICM20948 examples compile successfully
- YES: Temperature sensor works

## How to Apply Patches

If you're setting up Nimphea from scratch or have updated libDaisy, you'll need to apply these patches.

### Automatic Application (Recommended)

We include a script to apply all patches automatically:

```bash
# From the nimphea root directory:
./apply_patches.sh
```

### Manual Application

If you prefer to apply patches manually:

```bash
cd libDaisy
patch -p1 < ../patches/icm20948_fix.patch
```

Then rebuild libDaisy:

```bash
cd libDaisy
make clean
make
```

### Verification

After applying patches, verify they worked:

```bash
# Check if the line was changed:
grep -n "AuxillaryRegisterTransaction(true" libDaisy/src/dev/icm20948.h

# You should see line 686 with 4 arguments:
# 686:        return AuxillaryRegisterTransaction(true, slv_addr, reg_addr, 0);
```

## Upstream Status

| Patch | Submitted | PR Link | Status | Can Remove When |
|-------|-----------|---------|--------|-----------------|
| icm20948_fix.patch | TBD | TBD | Prepared | Merged to libDaisy master |

We are working with the libDaisy team to get these fixes merged upstream. Once they're in an official libDaisy release, we can remove the patches.

## Checking if Patches Are Applied

```bash
# Check ICM20948 patch:
grep "AuxillaryRegisterTransaction(true, slv_addr, reg_addr, 0)" libDaisy/src/dev/icm20948.h

# If this returns a match, the patch is applied
# If no match, you need to apply the patch
```

## Rebuilding After Patches

After applying any patches, you must rebuild libDaisy:

```bash
cd libDaisy
make clean
make
```

This regenerates the static library (`libDaisy/build/libdaisy.a`) that the Nim examples link against.

## Notes for Contributors

- **Don't modify libDaisy directly** - Always create patches instead
- **Test patches** - Ensure examples compile before committing patches  
- **Document thoroughly** - Explain what the patch fixes and why
- **Track upstream** - Update this README when PRs are submitted/merged
- **Remove when possible** - Delete patches once fixes are in official libDaisy releases

## Questions?

If you have issues applying patches or questions about why a patch is needed, please open an issue in the Nimphea repository.
