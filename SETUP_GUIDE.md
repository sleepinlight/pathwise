# Pathwise - Phase 1 Setup Guide

## Overview
This guide will help you complete the setup for Pathwise Phase 1, including required permissions, entitlements, and configuration steps.

## 1. Info.plist Permissions

Add the following privacy usage descriptions to your `Info.plist` file:

### Calendar Access
```xml
<key>NSCalendarsUsageDescription</key>
<string>Pathwise needs access to your calendar to find free time blocks for your walks.</string>
```

### Health Kit Access
```xml
<key>NSHealthShareUsageDescription</key>
<string>Pathwise would like to read your step count and activity data to track your walking progress.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Pathwise would like to update your activity data.</string>
```

### Location Access (for Weather)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pathwise needs your location to provide accurate weather forecasts for your walking windows.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Pathwise needs your location to provide accurate weather forecasts throughout the day.</string>
```

### Notifications
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>Pathwise sends you daily nudges to help you find the perfect time for a walk.</string>
```

## 2. Required Capabilities

In Xcode, add the following capabilities to your target:

### HealthKit
1. Go to your target's "Signing & Capabilities" tab
2. Click "+ Capability"
3. Add "HealthKit"
4. Enable "Clinical Health Records" if needed

### Push Notifications
1. Add "Push Notifications" capability
2. This enables local notifications for daily nudges

### App Groups (for Widget Support)
1. Add "App Groups" capability
2. Create a new app group: `group.com.pathwise.app`
3. Enable it for your main app target

### WeatherKit
1. Add "WeatherKit" capability
2. This requires an Apple Developer account with WeatherKit entitlement

## 3. Project Configuration

### Update Bundle Identifier
Make sure your bundle identifier matches your team and app:
- Example: `com.yourcompany.pathwise`

### Deployment Target
- Set minimum iOS deployment target to iOS 17.0 or later
- WeatherKit requires iOS 16.0+
- WidgetKit requires iOS 14.0+

## 4. Build Settings

### Swift Language Version
- Ensure Swift 5.9 or later is selected

### Background Modes (Optional for Phase 1)
For future phases, you may want to enable:
- Background fetch
- Remote notifications

## 5. Testing with Mock Data

Phase 1 is configured to use mock data by default for easier development and testing:

- **Weather**: Uses `WeatherService.fetchMockWeather()`
- **Calendar**: Uses `CalendarService.useMockCalendar()`
- **HealthKit**: Uses `HealthService.useMockHealthData()`

To switch to real data:
1. Open `DashboardViewModel.swift`
2. Comment out the `loadMockData()` call
3. Uncomment the `loadRealData()` method and call it instead
4. Ensure all permissions are properly configured

## 6. Widget Extension (Future Step)

Phase 1 includes widget infrastructure but not the actual widget extension. To add widgets:

1. **Create Widget Extension Target**
   - File → New → Target → Widget Extension
   - Name it "PathwiseWidget"
   - Add to the same app group: `group.com.pathwise.app`

2. **Implement Widget Views**
   - Use the designs from `WidgetPreview.swift` as reference
   - Implement `TimelineProvider` for widget updates
   - Use `WidgetDataManager.shared` to load data

3. **Widget Timeline**
   - Refresh every 15-30 minutes
   - Update when Golden Window changes
   - Use `WidgetCenter.shared.reloadAllTimelines()`

## 7. Color Assets

The app uses custom colors defined in code. Optionally, you can add these to your Assets.xcassets:

- **Sage Green**: #718355
- **Cream**: #F9F7F2
- **Slate Blue**: #4A5759

## 8. SF Symbols

The app uses SF Symbols for all icons. These are available in iOS 16+:
- `sparkles` - Golden Window indicator
- `figure.walk` - Walking/activity icon
- `sun.max.fill`, `cloud.rain.fill`, etc. - Weather icons
- `chart.bar.fill` - Weekly chart

## 9. Running the App

1. Open `pathwise.xcodeproj` in Xcode
2. Select your development team
3. Choose a simulator or physical device (iOS 17.0+)
4. Build and run (⌘R)

The app will:
- Show the dashboard with mock data
- Display a Golden Window based on mock calendar and weather
- Show activity stats with mock health data
- Display a weekly activity chart

## 10. Next Steps for Production

Before releasing to TestFlight or App Store:

1. **Switch to Real Data**
   - Enable real weather, calendar, and health data
   - Test all permission flows

2. **Add Widget Extension**
   - Create widget target
   - Implement small and medium widgets

3. **Implement Background Refresh**
   - Schedule daily window calculations
   - Update widget timelines

4. **Add User Preferences Screen**
   - Allow users to customize comfort range
   - Set walk duration preferences
   - Configure notification times

5. **Add Onboarding**
   - Request permissions gracefully
   - Explain app value proposition
   - Set up initial preferences

## 11. Known Limitations (Phase 1)

- Uses mock data by default
- No settings/preferences UI
- Widgets show preview designs only (no actual widget extension)
- No background refresh
- No location services integration yet
- WeatherKit API requires paid developer account

## 12. Architecture Overview

```
pathwise/
├── Models/              # Data models
│   ├── WeatherData.swift
│   ├── CalendarData.swift
│   ├── GoldenWindow.swift
│   └── ActivityData.swift
├── Services/           # Business logic & API integrations
│   ├── WindowFinderService.swift
│   ├── WeatherService.swift
│   ├── CalendarService.swift
│   ├── HealthService.swift
│   └── NotificationService.swift
├── Views/
│   ├── Dashboard/      # Main app views
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   └── Components/     # Reusable UI components
│       ├── GoldenWindowCard.swift
│       ├── ActivityStatsCard.swift
│       ├── WeeklyActivityChart.swift
│       └── WidgetPreview.swift
├── Utils/              # Utilities & helpers
│   └── DesignSystem.swift
└── Extensions/         # Swift extensions
    └── WidgetSupport.swift
```

## Support

For questions or issues:
1. Review the code comments in each file
2. Check Apple's documentation for specific APIs
3. Test with mock data first before enabling real integrations

---

**Created for Pathwise Phase 1** - A proactive walking concierge
