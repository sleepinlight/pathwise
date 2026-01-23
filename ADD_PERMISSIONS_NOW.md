# REQUIRED: Add Info.plist Permissions

## Why Permissions Aren't Showing

iOS requires **Info.plist usage descriptions** before showing permission popups. Without these entries, iOS silently denies the permission request.

## How to Add Permissions in Xcode

### Method 1: Using Xcode's Info Tab (Easiest)

1. **Open Xcode** and select your project
2. **Select the "pathwise" target** (not the project)
3. **Click the "Info" tab**
4. **Right-click in the Custom iOS Target Properties area**
5. **Select "Add Row"**
6. **Add each permission below**

### Method 2: Edit Info.plist Directly

1. **Find Info.plist** in the Project Navigator (should be in pathwise folder)
2. **Right-click → Open As → Source Code**
3. **Add the XML entries below** inside the `<dict>` tag

---

## Required Permissions to Add

### 1. Calendar Permission (CRITICAL for your issue)

**Key:** `NSCalendarsUsageDescription`
**Type:** String
**Value:** `Pathwise needs access to your calendar to find free time blocks for your walks.`

**Or in XML:**
```xml
<key>NSCalendarsUsageDescription</key>
<string>Pathwise needs access to your calendar to find free time blocks for your walks.</string>
```

### 2. Calendar Full Access (iOS 17+)

**Key:** `NSCalendarsFullAccessUsageDescription`
**Type:** String
**Value:** `Pathwise analyzes your schedule to find the perfect time for a walk.`

**Or in XML:**
```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>Pathwise analyzes your schedule to find the perfect time for a walk.</string>
```

### 3. Location Permission (for Weather)

**Key:** `NSLocationWhenInUseUsageDescription`
**Type:** String
**Value:** `Pathwise needs your location to provide accurate weather forecasts for your walking windows.`

**Or in XML:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pathwise needs your location to provide accurate weather forecasts for your walking windows.</string>
```

### 4. Health Permission (for Step Tracking)

**Key:** `NSHealthShareUsageDescription`
**Type:** String
**Value:** `Pathwise tracks your steps and activity to celebrate your walking progress.`

**Or in XML:**
```xml
<key>NSHealthShareUsageDescription</key>
<string>Pathwise tracks your steps and activity to celebrate your walking progress.</string>
```

**Key:** `NSHealthUpdateUsageDescription`
**Type:** String
**Value:** `Pathwise may update your health data.`

**Or in XML:**
```xml
<key>NSHealthUpdateUsageDescription</key>
<string>Pathwise may update your health data.</string>
```

---

## Complete Info.plist XML (Copy/Paste Ready)

If editing Info.plist as source code, add this inside the main `<dict>` tag:

```xml
<!-- Calendar Access -->
<key>NSCalendarsUsageDescription</key>
<string>Pathwise needs access to your calendar to find free time blocks for your walks.</string>

<key>NSCalendarsFullAccessUsageDescription</key>
<string>Pathwise analyzes your schedule to find the perfect time for a walk.</string>

<!-- Location Access (for Weather) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pathwise needs your location to provide accurate weather forecasts for your walking windows.</string>

<!-- Health Access (for Step Tracking) -->
<key>NSHealthShareUsageDescription</key>
<string>Pathwise tracks your steps and activity to celebrate your walking progress.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Pathwise may update your health data.</string>
```

---

## Step-by-Step Visual Guide

### Adding via Xcode Info Tab:

1. **Select Target**
   ```
   Project Navigator (⌘1) → pathwise project → TARGETS → pathwise
   ```

2. **Open Info Tab**
   ```
   Click "Info" tab (next to "General", "Signing & Capabilities")
   ```

3. **Add Each Permission**
   ```
   Hover over any row → Click "+" button
   OR Right-click → "Add Row"
   ```

4. **Select Permission Key**
   ```
   Start typing "Calendar" → Select "Privacy - Calendars Usage Description"
   Start typing "Location" → Select "Privacy - Location When In Use Usage Description"
   Start typing "Health" → Select "Privacy - Health Share Usage Description"
   ```

5. **Enter Value**
   ```
   Double-click the "Value" column
   Paste the description text
   ```

---

## After Adding Permissions

### Test Calendar Permission:

1. **Clean build folder**: Product → Clean Build Folder (⇧⌘K)
2. **Delete app** from simulator/device
3. **Build and run** (⌘R)
4. **Complete onboarding** to Calendar page
5. **Tap "Allow Calendar Access"**
6. **You should now see the iOS permission popup!** ✅

### What You'll See:

```
┌─────────────────────────────────┐
│ "pathwise" Would Like to        │
│ Access Your Calendar            │
│                                 │
│ Pathwise needs access to your   │
│ calendar to find free time      │
│ blocks for your walks.          │
│                                 │
│  [Don't Allow]  [Allow]         │
└─────────────────────────────────┘
```

---

## Troubleshooting

### Permission Popup Still Not Showing?

1. **Check Info.plist is in target**
   - Select Info.plist in Project Navigator
   - Look at File Inspector (⌘⌥1)
   - Ensure "Target Membership" has "pathwise" checked

2. **Clean and rebuild**
   ```
   ⇧⌘K (Clean Build Folder)
   Delete app from simulator
   ⌘R (Build and Run)
   ```

3. **Check Xcode console for errors**
   - Look for "This app has crashed because it attempted to access privacy-sensitive data..."
   - This means Info.plist entry is missing

4. **Verify spelling**
   - Keys must be EXACTLY as shown
   - `NSCalendarsUsageDescription` (plural "Calendars")
   - Case-sensitive!

---

## Quick Reference: All Permission Keys

| Permission | Key |
|------------|-----|
| Calendar | `NSCalendarsUsageDescription` |
| Calendar (iOS 17+) | `NSCalendarsFullAccessUsageDescription` |
| Location | `NSLocationWhenInUseUsageDescription` |
| Health Read | `NSHealthShareUsageDescription` |
| Health Write | `NSHealthUpdateUsageDescription` |
| Notifications | (No Info.plist entry needed) |

---

## Why This Wasn't Done Automatically

- Info.plist configuration requires manual Xcode project modification
- Each app needs custom descriptions that explain their specific use case
- Apple requires human-readable text that gets shown to users
- Can't be automated through code files alone

---

## Next Steps

1. ✅ Add the 5 permission entries above to Info.plist
2. ✅ Clean build folder
3. ✅ Delete app from simulator
4. ✅ Build and run
5. ✅ Test each permission in onboarding
6. ✅ See beautiful permission popups!

---

**Once added, you'll get proper iOS permission dialogs on all 4 permission screens!** 🎉
