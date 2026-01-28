# Routing Limitations & Future Improvements

## Current Approach: Waypoint-Based Loop Generation

### How It Works
1. Calculate 4 waypoints in a circle around the start location
2. Request a pedestrian route through all waypoints back to start
3. The routing engine connects waypoints using shortest walkable paths

### Known Issues

#### 1. Route Gaps/Discontinuities
**Problem**: Routes may have visual gaps or abrupt endings on the map

**Root Cause**: The routing API returns separate "legs" for each waypoint segment. When combining legs, there can be:
- Coordinate mismatches at waypoint boundaries
- Different polyline precision between legs
- The API choosing to not traverse certain segments

**Current Mitigation**: Smart coordinate concatenation that removes duplicates at boundaries

#### 2. Path Retracing
**Problem**: Routes sometimes retrace the same path instead of forming a scenic loop

**Root Cause**: Routing APIs are optimized for efficiency (shortest/fastest path), not for scenic variety. When waypoints are close together or in areas with limited path options, the most efficient route often means going back the same way.

**Why Waypoint Forcing Doesn't Always Work**:
- The routing engine still prioritizes efficiency between waypoints
- In suburban/residential areas, there may be limited connecting paths
- The algorithm doesn't have a concept of "already traveled" segments

**Current Mitigation**: Using `optimized_route` endpoint with `type: "through"` waypoints and increased `search_cutoff: 200m`

#### 3. Major Road Preference
**Problem**: Routes often prefer high-traffic arterial roads (e.g., Sharp Road) over quiet residential streets, even when pedestrian costing options should favor neighborhoods.

**Root Cause**: Valhalla's pedestrian costing model has limited controls for avoiding specific road classes. The routing engine fundamentally prioritizes distance efficiency:
- A straight line down a busy road appears "cheaper" than weaving through neighborhoods
- `use_living_street` parameter has minimal effect
- No direct "avoid primary/secondary roads" parameter exists
- OSM road classification may not always distinguish high-traffic from low-traffic roads

**Attempted Solutions**:
1. ✅ `use_living_street: 1.0` - Maximum preference for residential (limited effect)
2. ✅ `walkway_factor: 0.1` - Strong preference for dedicated paths (helps when available)
3. ✅ Increased waypoint radius (`miles / 3.5`) to push deeper into neighborhoods
4. ❌ `road_class_penalties` - Not a valid Valhalla parameter
5. ⚠️ `sidewalk_factor: 0.5` - Penalizes roads without sidewalk tags, but OSM data incomplete

**Why This Is Hard to Fix**:
- Valhalla is designed for navigation (get from A→B efficiently), not recreational routing
- The pedestrian costing model assumes users will tolerate some busy roads if it's shorter
- No way to tell the API "this road is unpleasant for walking" beyond OSM sidewalk tags
- Waypoint placement can only influence general direction, not micro-routing decisions

## Alternative Approaches to Consider

### Option 1: Overpass API + OSM Path Data
**Concept**: Query OpenStreetMap for actual pedestrian paths, trails, and sidewalks near the user, then programmatically connect them into loops.

**Pros**:
- Access to rich pedestrian infrastructure data
- Can identify parks, trails, greenways
- Can truly avoid retracing by marking segments as "used"

**Cons**:
- Complex algorithm needed to string paths together
- Need to handle path connectivity and accessibility
- Requires significant development effort

**Implementation Sketch**:
```swift
1. Query Overpass API for footways, paths, and tracks within radius
2. Build a graph of connected path segments
3. Use graph traversal to find loops of desired distance
4. Prefer segments that go through parks/greenways
5. Avoid using the same segment twice
```

### Option 2: Curated Route Database
**Concept**: Maintain a database of pre-generated "good" walking loops for major areas.

**Pros**:
- Guaranteed quality routes
- Can be curated for scenic value
- Instant results (no routing computation)

**Cons**:
- Requires building and maintaining route database
- Limited to areas with pre-generated routes
- Less flexible for custom distances

### Option 3: Genetic Algorithm Route Optimization
**Concept**: Generate many random waypoint patterns, evaluate each for loop quality, and evolve toward better loops.

**Pros**:
- Can optimize for multiple criteria (distance, no retracing, scenic value)
- Works with existing routing APIs

**Cons**:
- Slow (many API calls needed)
- Complex to implement
- Still limited by underlying routing API capabilities

### Option 4: Hybrid Approach
**Concept**: Combine waypoint-based routing with intelligent waypoint placement based on nearby landmarks/parks.

**Steps**:
1. Identify parks, trails, and landmarks within target radius
2. Place waypoints at interesting locations (park entrances, trail heads)
3. Weight routing to prefer greenways and park paths
4. Generate route through strategic waypoints

**Pros**:
- Leverages existing routing infrastructure
- More likely to create interesting routes
- Can still work in any location

**Cons**:
- Requires landmark/POI database
- Still depends on routing API's path choices

## Current Status & Recommendations

### What Works Now
- ✅ Reliable distance estimation
- ✅ HealthKit pace integration for accurate time estimates
- ✅ Map visualization with proper tiles
- ✅ Basic loop formation (works better in areas with grid streets)

### What Needs Improvement
- ❌ **Major road avoidance** - Routes still use high-traffic arterials (Sharp Road, etc.)
- ⚠️ Loop quality in suburban areas with limited path connectivity
- ✅ Visual route continuity improved with `through` waypoints
- ⚠️ Path retracing in some locations

### Recommended Next Steps

**Short Term** (Quick Wins):
1. ✅ Use HealthKit workout pace for better time estimates
2. ✅ Improve coordinate concatenation to reduce visual gaps
3. ✅ Use `optimized_route` with `through` waypoints
4. ⚠️ **Generate multiple route candidates** and let user choose best one:
   - Try 3-5 different start bearings
   - Score routes based on: total distance on primary/secondary roads, elevation change, number of turns
   - Present top 2-3 options to user
5. ⚠️ **Add "Regenerate Route" button** - Let users quickly try different variations

**Medium Term** (Recommended):
- Implement Option 4 (Hybrid Approach):
  - Integrate with Overpass API to find nearby parks/trails
  - Place waypoints at park entrances and trail heads
  - This should significantly improve loop quality without requiring complex path-finding

**Long Term** (If this becomes a core feature):
- Implement Option 1 (Full OSM Path Integration):
  - Build custom loop-finding algorithm
  - This gives complete control over route quality
  - Best user experience but significant development effort

## Technical Notes

### Why Stadia Maps/Valhalla Has These Limitations
Valhalla (the routing engine behind Stadia Maps) is designed for:
- Turn-by-turn navigation
- Efficient point-to-point routing
- Respecting traffic rules and pedestrian accessibility

It is **not** designed for:
- Recreational loop generation
- Scenic route optimization
- Avoiding previously-traveled segments

This is true of most routing APIs (Google, Mapbox, etc.). Recreational route planning is a specialized use case that typically requires custom algorithms.

### Performance Considerations
- Current approach: 1 API call per route
- OSM approach: 1-2 API calls + client-side pathfinding
- Genetic approach: 10-50 API calls per route (not practical)

## Conclusion

The current implementation provides a reasonable MVP for loop generation, but has inherent limitations due to relying on navigation-focused routing APIs. For production quality, consider implementing the Hybrid Approach (Option 4) which balances development effort with improved loop quality.
