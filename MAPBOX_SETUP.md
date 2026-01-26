# Mapbox Setup Guide for Paths Feature

The Paths feature uses the Mapbox Directions API to generate walking loop routes. Follow these steps to get it working:

## 1. Create a Mapbox Account

1. Go to [https://account.mapbox.com/auth/signup/](https://account.mapbox.com/auth/signup/)
2. Sign up for a free account
3. The free tier includes:
   - 100,000 requests per month for Directions API
   - Unlimited map loads

## 2. Get Your Access Token

1. Once logged in, go to [https://account.mapbox.com/access-tokens/](https://account.mapbox.com/access-tokens/)
2. You'll see a "Default public token" already created
3. Click "Create a token" to create a new one specifically for this app (recommended)
4. Give it a name like "Pathwise iOS App"
5. Under "Token scopes", make sure these are checked:
   - **Styles:Read** (for map display)
   - **Directions:Read** (for route generation)
6. Click "Create token"
7. Copy your new access token (starts with `pk.`)

## 3. Add Token to Your App

1. Open `pathwise/Config/MapboxConfig.swift`
2. Replace `"YOUR_MAPBOX_ACCESS_TOKEN_HERE"` with your actual token:

```swift
static let accessToken = "pk.eyJ1IjoieW91cnVzZXJuYW1lIiwi..."
```

⚠️ **Important**: Never commit your access token to a public repository!

## 4. Test the Feature

1. Build and run the app on your device or simulator
2. Navigate to the "Paths" tab
3. Grant location permissions when prompted
4. Select a distance (1, 2, 3, or 5 miles)
5. Tap "Find a Path"
6. The app will generate a random walking loop and display it on the map

## How It Works

The Paths feature uses a "pivot point" algorithm:

1. Takes your current location as the start/end point (Point A)
2. Calculates a "pivot point" (Point B) at a random bearing
3. Requests a walking route: A → B → A
4. The Mapbox API returns a pedestrian-friendly loop route

The algorithm includes:
- **Winding factor**: Distance is divided by 2.5 to account for street curves
- **Safety features**: Excludes motorways and major highways
- **Sidewalk preference**: Uses `walkway_bias=1.0` to prioritize footpaths

## API Usage & Costs

With Mapbox's free tier (100,000 requests/month):
- Each route generation = 1 API request
- If users generate ~10 routes/day = ~300 requests/month
- You can support ~330 daily active users on the free tier

## Troubleshooting

### "Invalid API token" error
- Make sure you copied the entire token (it's quite long)
- Verify the token has the correct scopes (Directions:Read)
- Check that there are no extra spaces in the token string

### "No suitable route found" error
- Try a different distance
- Make sure you're in an area with good pedestrian infrastructure
- The random bearing might have picked an area with limited walkways

### Location not working
- Check that location permissions are enabled in Settings > Privacy > Location Services
- Make sure "Pathwise" is set to "While Using the App"

## Next Steps (Future Enhancements)

Potential improvements to the Paths feature:
- Save favorite routes
- Route history
- Turn-by-turn navigation
- Elevation profiles
- Route sharing
- Custom distance input (not just presets)
- Filter by terrain type (urban vs trails)
