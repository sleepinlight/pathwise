# Quick Fix Checklist - Get Permissions Working

## Your Error:
```
❌ Missing com.apple.developer.healthkit entitlement
```

## Quick Fix (2 minutes):

### Step 1: Add HealthKit Capability
1. Open Xcode
2. Select **pathwise target** → **Signing & Capabilities** tab
3. Click **"+ Capability"** button
4. Search **"HealthKit"**
5. Double-click to add

### Step 2: Add Info.plist Entries
1. Select **pathwise target** → **Info** tab
2. Right-click → **Add Row** (5 times)
3. Add these keys:

```
Privacy - Calendars Usage Description
Privacy - Calendars Full Access Usage Description
Privacy - Location When In Use Usage Description
Privacy - Health Share Usage Description
Privacy - Health Update Usage Description
```

**Quick Copy/Paste Values:**
```
Pathwise needs access to your calendar to find free time blocks for your walks.
Pathwise analyzes your schedule to find the perfect time for a walk.
Pathwise needs your location to provide accurate weather forecasts for your walking windows.
Pathwise tracks your steps and activity to celebrate your walking progress.
Pathwise may update your health data.
```

### Step 3: Add Push Notifications Capability
1. Still in **Signing & Capabilities** tab
2. Click **"+ Capability"**
3. Search **"Push Notifications"**
4. Double-click to add

### Step 4: Clean & Rebuild
1. Clean: **⇧⌘K**
2. Delete app from simulator
3. Build & Run: **⌘R**

---

## Expected Result:

✅ No more "Missing entitlement" errors
✅ Calendar permission popup appears
✅ Health permission popup appears
✅ Notification permission popup appears
✅ All onboarding permissions work!

---

## Summary: What You Need

**Capabilities (Signing & Capabilities tab):**
- ✅ HealthKit
- ✅ Push Notifications
- ⚠️ WeatherKit (optional - requires paid Apple Developer account)

**Info.plist (Info tab):**
- ✅ NSCalendarsUsageDescription
- ✅ NSCalendarsFullAccessUsageDescription
- ✅ NSLocationWhenInUseUsageDescription
- ✅ NSHealthShareUsageDescription
- ✅ NSHealthUpdateUsageDescription

---

## Detailed Guides Available:

- `ADD_CAPABILITIES_NOW.md` - Full capability guide
- `ADD_PERMISSIONS_NOW.md` - Full Info.plist guide
- `QUICK_PERMISSIONS_REFERENCE.md` - Copy/paste reference

---

**Total time: ~2 minutes to fix everything!** ⚡️
