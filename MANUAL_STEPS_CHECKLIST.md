# Manual Steps Checklist

Complete these steps in Xcode to finish the Paths migration:

## ☐ 1. Add MapLibre Native Package

In Xcode:
- [ ] Open `pathwise.xcodeproj`
- [ ] Select project → `pathwise` target → Package Dependencies tab
- [ ] Click `+` button
- [ ] Paste URL: `https://github.com/maplibre/maplibre-gl-native-distribution`
- [ ] Click "Add Package"
- [ ] Select "MapLibre" and click "Add Package"

## ☐ 2. Add Stadia Maps API Key

- [ ] Sign up at https://client.stadiamaps.com/signup/
- [ ] Create API key in dashboard
- [ ] Open `pathwise/Config/StadiaMapsConfig.swift`
- [ ] Replace `"YOUR_STADIA_MAPS_API_KEY"` with your actual key

## ☐ 3. Uncomment MapLibre Code

In `pathwise/Views/Components/PathwiseMapView.swift`:
- [ ] Uncomment line: `import MapLibre`
- [ ] Replace placeholder `makeUIView` with commented MLNMapView implementation
- [ ] Uncomment the full `updateUIView` implementation
- [ ] Uncomment all Coordinator delegate methods

## ☐ 4. Verify File Target Membership

Check these files are in `pathwise` target (File Inspector → Target Membership):
- [ ] `StadiaMapsConfig.swift`
- [ ] `RoutingService.swift`
- [ ] `PathwiseMapView.swift`

## ☐ 5. Build and Test

- [ ] Build project (⌘B) - should succeed
- [ ] Run on simulator/device
- [ ] Go to Paths tab
- [ ] Test route generation with different distances

## ☐ 6. Optional Cleanup

If everything works, remove old Mapbox files:
- [ ] Delete `pathwise/Services/RouteGenerationService.swift`
- [ ] Delete `pathwise/Config/MapboxConfig.swift`
- [ ] Remove old `MapViewWithRoute` code from `PathsView.swift` (lines 150-242)

---

**Expected Result:** Map displays with MapLibre, routes generate using Stadia Maps with pedestrian-optimized pathfinding, routes render in green (#718355).
