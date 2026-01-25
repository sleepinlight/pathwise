# Widget Setup Guide

## App Groups Configuration

To enable data sharing between the main app and widget, you need to set up App Groups in Xcode.

### Step 1: Enable App Groups for Main App

1. In Xcode, select the **pathwise** project in the Navigator
2. Select the **pathwise** target
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **App Groups**
6. Click the **+** button under App Groups
7. Enter the identifier: `group.com.pathwise.app`
8. Make sure it's checked ✅

### Step 2: Enable App Groups for Widget Extension

1. Select the **pathwiseWidget** target
2. Go to the **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click the **+** button under App Groups
6. Enter the **same identifier**: `group.com.pathwise.app`
7. Make sure it's checked ✅

### Step 3: Update App Group Identifier (if needed)

If you want to use a different App Group identifier:

1. Open `pathwise/Utils/WidgetDataManager.swift`
2. Update line 22:
   ```swift
   private let appGroupIdentifier = "group.com.pathwise.app"
   ```
3. Change it to your preferred identifier (must match what you set in Capabilities)

### Step 4: Add WidgetDataManager to Widget Target

1. In Project Navigator, find `pathwise/Utils/WidgetDataManager.swift`
2. Select the file
3. In the File Inspector (right sidebar), under **Target Membership**
4. Check **both** boxes:
   - ✅ pathwise
   - ✅ pathwiseWidget

This makes the file available to both targets.

### Step 5: Verify File Memberships

Make sure these files are shared with the widget:

**Files in BOTH targets (pathwise + pathwiseWidget):**
- ✅ `Models/GoldenWindow.swift`
- ✅ `Models/WeatherData.swift`
- ✅ `Utils/DesignSystem.swift`
- ✅ `Utils/WidgetDataManager.swift`

**Files ONLY in pathwiseWidget target:**
- ✅ `GoldenWindowWidget.swift`
- ✅ `PathwiseWidgetBundle.swift`

### Step 6: Build and Run

1. Select the **pathwise** scheme
2. Build and run the main app
3. The app will automatically update widget data when:
   - Golden windows are calculated
   - Step count changes
   - User opens the app

### Step 7: Add Widget to Home Screen

1. Long press on your home screen
2. Tap the **+** button in the top corner
3. Search for **Pathwise**
4. Choose **Golden Window** widget
5. Select Small or Medium size
6. Tap **Add Widget**

## How It Works

### Data Flow

```
Main App → WidgetDataManager → App Group UserDefaults → Widget
```

1. **DashboardViewModel** updates window/step data
2. **updateWidgetData()** creates a `WidgetData` object
3. **WidgetDataManager.saveWidgetData()** saves to shared UserDefaults
4. **WidgetCenter.reloadAllTimelines()** tells widgets to refresh
5. **Widget Provider** reads data from shared UserDefaults
6. **Widget displays** the latest data

### When Widgets Update

Widgets automatically update when:

- ✅ Main app saves new data (immediate)
- ✅ 15-minute timer expires (background refresh)
- ✅ User force-touches widget (manual refresh)
- ✅ System wakes widget (opportunistic refresh)

### Troubleshooting

**Widget shows sample data instead of real data:**
- Check App Groups are enabled and identifiers match
- Verify WidgetDataManager is in both target memberships
- Check console logs for "✅ Widget data saved" messages
- Try deleting and re-adding the widget

**Build errors:**
- Make sure all shared files have correct target membership
- Clean build folder (Cmd+Shift+K)
- Delete derived data

**Widget not updating:**
- Check that `WidgetCenter.shared.reloadAllTimelines()` is being called
- Verify App Group identifier matches in both targets
- Check Privacy settings → Widgets are allowed

## App Group Data Structure

The shared data is stored as JSON in UserDefaults:

```swift
struct WidgetData: Codable {
    let goldenWindow: GoldenWindow?
    let additionalWindows: [GoldenWindow]
    let todaySteps: Int
    let stepGoal: Int
    let isInGoldenWindow: Bool
    let lastUpdated: Date
}
```

Location: `group.com.pathwise.app` → `pathwise.widget.data`
