# Widget Build Errors - Fix Checklist

## Current Errors and Fixes

### ✅ Fixed: Renamed `WidgetData` → `PathwiseWidgetData`
This avoids naming conflicts between targets.

### ✅ Fixed: Renamed `WidgetDataManager` → `PathwiseWidgetDataManager`
Linter automatically renamed the class. Updated all references in:
- DashboardViewModel.swift
- GoldenWindowWidget.swift

### ✅ Fixed: Target Membership Issues
All files are configured correctly with proper target membership.

## Step-by-Step Fixes in Xcode

### 1. Fix `@main` Conflict (PathwiseWidgetBundle.swift)

**Problem:** "'main' attribute can only apply to one type in a module"

**Fix:**
1. Select `PathwiseWidgetBundle.swift` in Project Navigator
2. Open File Inspector (⌥⌘1 or right sidebar)
3. Under "Target Membership":
   - ❌ **UNCHECK** `pathwise`
   - ✅ **CHECK** `pathwiseWidget` only

### 2. Fix Widget Can't Find WidgetDataManager

**Problem:** "Cannot find 'WidgetDataManager' in scope"

**Fix:**
1. Select `pathwise/Utils/WidgetDataManager.swift`
2. Open File Inspector (⌥⌘1)
3. Under "Target Membership":
   - ✅ **CHECK** `pathwise`
   - ✅ **CHECK** `pathwiseWidget`

### 3. Verify Shared Files

Make sure these files are in **BOTH** targets:

| File | pathwise | pathwiseWidget |
|------|----------|----------------|
| `Models/GoldenWindow.swift` | ✅ | ✅ |
| `Models/WeatherData.swift` | ✅ | ✅ |
| `Utils/DesignSystem.swift` | ✅ | ✅ |
| `Utils/WidgetDataManager.swift` | ✅ | ✅ |

### 4. Verify Widget-Only Files

Make sure these files are in **WIDGET TARGET ONLY**:

| File | pathwise | pathwiseWidget |
|------|----------|----------------|
| `pathwiseWidget/GoldenWindowWidget.swift` | ❌ | ✅ |
| `pathwiseWidget/PathwiseWidgetBundle.swift` | ❌ | ✅ |

### 5. Verify App-Only Files

Make sure the main app file is in **APP TARGET ONLY**:

| File | pathwise | pathwiseWidget |
|------|----------|----------------|
| `pathwise/pathwiseApp.swift` | ✅ | ❌ |

## How to Check Target Membership

1. **Select any file** in Project Navigator
2. Press **⌥⌘1** (Option+Command+1) to open File Inspector
3. Look for **"Target Membership"** section
4. Check/uncheck boxes for each target

## After Fixing

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build Main App**: Select `pathwise` scheme → Build (⌘B)
3. **Build Widget**: Select `pathwiseWidget` scheme → Build (⌘B)

## Expected Result

Both builds should succeed with no errors:
- ✅ Main app builds successfully
- ✅ Widget extension builds successfully
- ✅ Widget shows in widget gallery on device/simulator
