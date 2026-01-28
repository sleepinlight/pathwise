# HealthKit Integration for Walking Pace

## Overview

The Paths feature now uses HealthKit to fetch your average walking speed and provide more accurate time estimates.

## Setup Steps

### 1. Add HealthKit Capability

1. Open `pathwise.xcodeproj` in Xcode
2. Select the **pathwise** project in the navigator
3. Select the **pathwise** target
4. Go to the **Signing & Capabilities** tab
5. Click the **+ Capability** button
6. Search for **HealthKit** and add it

### 2. Add Privacy Description

Add this to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Pathwise uses your walking data to provide accurate route time estimates based on your pace.</string>
```

Or in Xcode:
1. Open `Info.plist`
2. Click **+** to add a new row
3. Key: `Privacy - Health Share Usage Description`
4. Value: `Pathwise uses your walking data to provide accurate route time estimates based on your pace.`

## How It Works

### Data Collection

- **Metric**: Walking Speed from HealthKit
- **Timeframe**: Last 30 days of walking data
- **Permission**: Read-only access requested on first route generation
- **Frequency**: Cached per session (fetched once, reused for all routes)

### Time Calculation

**With HealthKit Permission:**
- Uses your average walking speed from the last 30 days
- Example: If you walk at 4.3 mph (14 min/mile pace), a 3-mile route = ~42 minutes

**Without HealthKit Permission:**
- Falls back to default: 3.0 mph (20 min/mile pace)
- Example: A 3-mile route = 60 minutes

### Implementation Details

```swift
// HealthKitService.swift
- fetchAverageWalkingSpeed() -> Returns mph or nil
- calculateWalkingTime(distance:userSpeed:) -> Returns minutes
```

The service:
1. Requests authorization for `walkingSpeed` data type
2. Queries statistics from last 30 days
3. Calculates discrete average
4. Converts from m/s to mph
5. Caches result for session

## Privacy

- **No data is stored** outside of HealthKit
- **No data is transmitted** to any servers
- **Read-only access** - Pathwise never writes to HealthKit
- Permission can be revoked anytime in Settings → Health → Data Access & Devices

## Console Logging

Look for these log lines:
- `⚕️ Average walking speed: X.X mph (X.X min/mile)` - HealthKit data retrieved
- `⚕️ HealthKit not available on this device` - Running on simulator or device without HealthKit
- `⚕️ No walking speed data available` - User has no recent walking data
- `🗺️ Stadia time estimate: X minutes` - Route provider's estimate
- `🗺️ HealthKit-adjusted time: X minutes` - Personalized estimate

## Fallback Behavior

If HealthKit data is unavailable (denied permission, no data, simulator):
- Uses 3.0 mph (20 min/mile) as default walking pace
- This is a conservative estimate for general fitness level
- Still provides reasonable time estimates

## Benefits

1. **Personalized Estimates**: Time predictions match your actual walking pace
2. **Better Planning**: More accurate estimates help schedule your walks
3. **Motivational**: See your pace reflected in real-time route planning
4. **Privacy-Focused**: All data stays on device, no cloud sync

## Testing

To test with different paces:
1. Grant HealthKit permission
2. Generate a route - check console for your walking speed
3. Compare Stadia estimate vs HealthKit-adjusted estimate
4. Verify the HealthKit estimate matches your expected pace

Example output:
```
⚕️ Average walking speed: 4.3 mph (13.95 min/mile)
🗺️ Total route distance: 2.8 miles
🗺️ Stadia time estimate: 56.2 minutes (conservative)
🗺️ HealthKit-adjusted time: 39.1 minutes (personalized)
```
