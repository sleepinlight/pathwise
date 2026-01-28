# Paths Feature Migration Guide

This guide will help you complete the migration from Mapbox to MapLibre + Stadia Maps for the Paths feature.

## Overview

The paths feature has been refactored to use:
- **MapLibre Native** for map rendering
- **Stadia Maps** for pedestrian routing with better walkability factors

## Step 1: Add MapLibre Native Dependency

1. Open `pathwise.xcodeproj` in Xcode
2. Select the project in the Project Navigator
3. Select the `pathwise` target
4. Go to the **Package Dependencies** tab
5. Click the **+** button
6. Enter the package URL: `https://github.com/maplibre/maplibre-gl-native-distribution`
7. Click **Add Package**
8. Select **MapLibre** and click **Add Package**

## Step 2: Get a Stadia Maps API Key

1. Go to https://client.stadiamaps.com/signup/
2. Create a free account
3. Navigate to **API Keys** in the dashboard
4. Create a new API key
5. Copy the API key

## Step 3: Configure Stadia Maps API Key

Open `pathwise/Config/StadiaMapsConfig.swift` and replace the placeholder:

```swift
static let apiKey = "YOUR_STADIA_MAPS_API_KEY"
```

With your actual API key:

```swift
static let apiKey = "your-actual-api-key-here"
```

## Step 4: Uncomment MapLibre Code

After adding the MapLibre dependency, you need to uncomment the MapLibre-specific code in `PathwiseMapView.swift`:

1. Open `pathwise/Views/Components/PathwiseMapView.swift`
2. Uncomment the MapLibre import at the top:
   ```swift
   import MapLibre
   ```
3. Replace the placeholder `makeUIView` implementation with the commented MLNMapView code
4. Uncomment the `updateUIView` implementation
5. Uncomment the Coordinator delegate methods

## Step 5: Add New Files to Xcode Target

Make sure these new files are added to the `pathwise` target:

- `pathwise/Config/StadiaMapsConfig.swift`
- `pathwise/Services/RoutingService.swift`
- `pathwise/Views/Components/PathwiseMapView.swift`

To verify:
1. Select each file in Project Navigator
2. In File Inspector (right sidebar), check that `pathwise` is selected under **Target Membership**

## Step 6: Build and Test

1. Build the project (⌘B)
2. Run on simulator or device
3. Navigate to the Paths tab
4. Select a distance and tap "Find a Path"

## What Changed

### Removed
- `RouteGenerationService.swift` (Mapbox-based)
- `MapboxConfig.swift`
- `MapViewWithRoute` UIViewRepresentable

### Added
- `RoutingService.swift` - Actor-based routing service using Stadia Maps
- `StadiaMapsConfig.swift` - Configuration for Stadia Maps API
- `PathwiseMapView.swift` - MapLibre-based map view

### Modified
- `PathsViewModel.swift` - Now uses `RoutingService` instead of `RouteGenerationService`
- `PathsView.swift` - Now uses `PathwiseMapView` instead of `MapViewWithRoute`

## Routing Configuration

The new routing service uses these pedestrian-optimized parameters:

```json
{
  "sidewalk_factor": 1.0,  // Strongly prefer sidewalks
  "walkway_factor": 1.0,   // Strongly prefer pedestrian walkways
  "alley_factor": 0.1,     // Avoid alleys
  "driveway_factor": 0.1   // Avoid driveways
}
```

## Route Visualization

Routes are now rendered in pathwise brand green (`#718355`) with a width of 5.0 points, matching the design system.

## Troubleshooting

### "Add MapLibre Native dependency to enable map" message
- The MapLibre dependency hasn't been added yet. Follow Step 1.

### Build errors about MLNMapView
- Make sure you've uncommented all the MapLibre code in `PathwiseMapView.swift` after adding the dependency.

### 401 API Error from Stadia Maps
- Your API key is missing or invalid. Check `StadiaMapsConfig.swift`.

### Routes not appearing
- Check Xcode console for debug logs starting with 🗺️
- Verify location permissions are granted
- Ensure the Stadia Maps API key is valid

## Debug Logging

The routing service includes comprehensive logging:
- `🗺️ Pivot Point:` - Shows calculated pivot point
- `🗺️ Distance from start to pivot:` - Pivot distance validation
- `🗺️ Stadia Maps Request URL:` - Full API request
- `🗺️ Stadia Maps Response Status:` - HTTP status code
- `🗺️ Route has X coordinate points:` - Polyline detail
- `🗺️ Route distance:` - Final route distance

## Next Steps

After completing the migration:

1. Remove old Mapbox files if no longer needed:
   - `pathwise/Services/RouteGenerationService.swift`
   - `pathwise/Config/MapboxConfig.swift`

2. Test various distances (1-5 miles) to ensure routes generate correctly

3. Verify routes avoid high-traffic roads and prefer walkable paths

4. Test in different locations to ensure the pivot point algorithm works well
