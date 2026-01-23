# REQUIRED: Add Xcode Capabilities

## What Are Capabilities?

Capabilities are special entitlements that your app needs to access iOS frameworks like HealthKit, WeatherKit, etc. They're different from Info.plist permissions.

---

## How to Add Capabilities in Xcode

### Step-by-Step:

1. **Open your project in Xcode**

2. **Select the project** in the Project Navigator (left sidebar)

3. **Select the "pathwise" target** (under TARGETS, not PROJECTS)

4. **Click the "Signing & Capabilities" tab** (next to "General" and "Info")

5. **Click the "+ Capability" button** (top left of the main panel)

6. **Add each capability below**

---

## Required Capabilities

### 1. HealthKit (CRITICAL - Fixes Your Error)

**This is the missing capability causing your error!**

**How to Add:**
1. Click **"+ Capability"**
2. Search for **"HealthKit"**
3. Double-click **"HealthKit"**
4. A new "HealthKit" section appears in your capabilities list

**What You'll See:**
```
┌─────────────────────────────────┐
│ HealthKit                       │
│ ☑ Clinical Health Records       │
│ ☐ Background Delivery           │
└─────────────────────────────────┘
```

**Options:**
- ☑ Check "Clinical Health Records" (optional, but recommended)
- Background Delivery: Leave unchecked for Phase 1

---

### 2. Push Notifications

**For daily nudges and reminders**

**How to Add:**
1. Click **"+ Capability"**
2. Search for **"Push Notifications"**
3. Double-click **"Push Notifications"**

**What You'll See:**
```
┌─────────────────────────────────┐
│ Push Notifications              │
│ (No additional configuration)   │
└─────────────────────────────────┘
```

---

### 3. WeatherKit (Optional for Phase 1)

**For real weather data (requires paid Apple Developer account)**

**How to Add:**
1. Click **"+ Capability"**
2. Search for **"WeatherKit"**
3. Double-click **"WeatherKit"**

**Note:**
- WeatherKit requires a **paid Apple Developer Program membership** ($99/year)
- Without it, the app will use mock weather data (which works fine!)
- If you see an error when adding this, you can skip it for now

**What You'll See:**
```
┌─────────────────────────────────┐
│ WeatherKit                      │
│ (Automatic configuration)       │
└─────────────────────────────────┘
```

---

### 4. App Groups (For Widgets - Future Phase)

**Optional for Phase 1, but good to set up now**

**How to Add:**
1. Click **"+ Capability"**
2. Search for **"App Groups"**
3. Double-click **"App Groups"**
4. Click **"+"** to add a new group
5. Enter: **`group.com.yourteam.pathwise`**
   - Replace `yourteam` with your actual team identifier
   - Example: `group.com.andy.pathwise`
6. Click **"OK"**

**What You'll See:**
```
┌─────────────────────────────────┐
│ App Groups                      │
│ ☑ group.com.yourteam.pathwise   │
└─────────────────────────────────┘
```

---

## Complete Capabilities List

After adding all capabilities, you should see:

```
Signing & Capabilities
├── Signing
│   └── Team: Your Team
│   └── Bundle Identifier: com.yourteam.pathwise
├── HealthKit ✓
│   └── ☑ Clinical Health Records
├── Push Notifications ✓
├── WeatherKit ✓ (optional)
└── App Groups ✓ (optional)
    └── ☑ group.com.yourteam.pathwise
```

---

## After Adding Capabilities

### Test HealthKit (Your Error):

1. **Clean build folder**: ⇧⌘K
2. **Delete app** from simulator/device
3. **Build and run**: ⌘R
4. **Go to Health permission page** in onboarding
5. **Tap "Allow Health Access"**
6. **You should now see the HealthKit permission popup!** ✅

**The error will be gone:**
```
❌ Before: "Missing com.apple.developer.healthkit entitlement"
✅ After:  Permission popup appears!
```

---

## Troubleshooting

### "Capability not found" or grayed out?

**Cause:** Missing team selection

**Fix:**
1. Go to **"Signing & Capabilities"** tab
2. Under **"Signing"** section
3. Select your **Team** from dropdown
4. If no teams available, add an Apple ID:
   - Xcode → Settings → Accounts → Add Account

---

### WeatherKit shows an error?

**Error:** "WeatherKit requires enrollment in Apple Developer Program"

**Fix:**
- Skip WeatherKit for now
- App will use mock weather data (works great!)
- Can add later when you have paid developer account

---

### HealthKit still not working after adding?

**Checklist:**
1. ✅ Added HealthKit capability
2. ✅ Added Info.plist entries (`NSHealthShareUsageDescription`)
3. ✅ Cleaned build folder (⇧⌘K)
4. ✅ Deleted app from simulator
5. ✅ Rebuilt and ran

**Still issues?**
- Check Xcode console for new error messages
- Verify capability appears in "Signing & Capabilities"
- Ensure it has a checkmark (not grayed out)

---

### Calendar/Location permissions still not working?

Those only need **Info.plist entries**, not capabilities:
- See `ADD_PERMISSIONS_NOW.md` for Info.plist setup
- See `QUICK_PERMISSIONS_REFERENCE.md` for quick reference

---

## Summary: What Needs What?

| Feature | Info.plist | Capability | Both |
|---------|-----------|-----------|------|
| Calendar | ✓ | | |
| Location | ✓ | | |
| Health | | | ✓ |
| Notifications | | ✓ | |
| Weather | | ✓ | |

**Calendar & Location:** Just Info.plist
**Health:** Needs both Info.plist AND capability
**Notifications:** Just capability
**WeatherKit:** Just capability (optional)

---

## Quick Test After Setup

Run this checklist:

1. **HealthKit**
   ```
   Go to Health permission page
   Tap "Allow Health Access"
   ✅ See iOS HealthKit permission dialog
   ```

2. **Calendar**
   ```
   Go to Calendar permission page
   Tap "Allow Calendar Access"
   ✅ See iOS Calendar permission dialog
   ```

3. **Notifications**
   ```
   Go to Notifications permission page
   Tap "Allow Notifications"
   ✅ See iOS notification permission dialog
   ```

4. **No Console Errors**
   ```
   Check Xcode console
   ✅ No "Missing entitlement" errors
   ```

---

## Priority Order

**Fix your immediate error first:**

1. **Add HealthKit capability** (fixes current error)
2. **Add Info.plist entries** (fixes Calendar/Location)
3. **Add Push Notifications** (enables notifications)
4. **Add WeatherKit** (optional, for real weather)
5. **Add App Groups** (optional, for future widgets)

---

## Next Steps

1. ✅ Open Xcode
2. ✅ Go to Signing & Capabilities tab
3. ✅ Add HealthKit capability
4. ✅ Add Push Notifications capability
5. ✅ Clean build (⇧⌘K)
6. ✅ Delete app from simulator
7. ✅ Build and run (⌘R)
8. ✅ Test all permissions!

---

**Once you add the HealthKit capability, your error will disappear!** 🎉
