# Quick Permissions Reference

## Copy/Paste Into Info.plist

Open Info.plist as **Source Code** and paste this inside the `<dict>` tag:

```xml
<key>NSCalendarsUsageDescription</key>
<string>Pathwise needs access to your calendar to find free time blocks for your walks.</string>

<key>NSCalendarsFullAccessUsageDescription</key>
<string>Pathwise analyzes your schedule to find the perfect time for a walk.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Pathwise needs your location to provide accurate weather forecasts for your walking windows.</string>

<key>NSHealthShareUsageDescription</key>
<string>Pathwise tracks your steps and activity to celebrate your walking progress.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Pathwise may update your health data.</string>
```

## Or Add via Xcode UI

1. Select **pathwise target** → **Info tab**
2. Click **+** to add each row:

| Key | Value |
|-----|-------|
| Privacy - Calendars Usage Description | `Pathwise needs access to your calendar to find free time blocks for your walks.` |
| Privacy - Calendars Full Access Usage Description | `Pathwise analyzes your schedule to find the perfect time for a walk.` |
| Privacy - Location When In Use Usage Description | `Pathwise needs your location to provide accurate weather forecasts for your walking windows.` |
| Privacy - Health Share Usage Description | `Pathwise tracks your steps and activity to celebrate your walking progress.` |
| Privacy - Health Update Usage Description | `Pathwise may update your health data.` |

## After Adding

1. Clean build (⇧⌘K)
2. Delete app from simulator
3. Run (⌘R)
4. See permission popups! ✅
