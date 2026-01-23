# Pathwise

> Your proactive walking concierge that finds the perfect time to take a walk

## Overview

Pathwise is an iOS app that identifies the "Golden Window" for walking based on your calendar availability and weather conditions. It uses intelligent scoring to find the best 20-30 minute window in your day when the weather is comfortable and your schedule is free.

## Features (Phase 1)

### Core Features
- **Golden Window Algorithm**: Analyzes your calendar and weather to find the optimal walking time
- **Smart Scoring System**: Weighs temperature, daylight, weather conditions, and precipitation
- **Activity Tracking**: Integrates with HealthKit to show steps, distance, and active minutes
- **Weekly Overview**: Visualizes your walking progress throughout the week

### User Interface
- **Main Dashboard**: Clean, friendly interface with your Golden Window and activity stats
- **Weather Integration**: Real-time weather data using Apple's WeatherKit
- **Calendar Integration**: Automatically finds free time blocks in your schedule
- **Widget Designs**: Preview designs for small and medium home screen widgets

### Notifications
- **Daily Nudge**: Morning notification with your Golden Window for the day
- **Window Reminders**: Optional reminder before your Golden Window starts

## Design Philosophy

### Colors
- **Sage Green** (#718355) - Primary accent, natural and calming
- **Cream** (#F9F7F2) - Background, warm and inviting
- **Slate Blue** (#4A5759) - Text, professional and readable

### Typography
- Rounded Sans-Serif font (System with `.rounded` design)
- Friendly, approachable tone
- Clear hierarchy with varied weights

### Visual Style
- Rounded corners for a soft, friendly feel
- Subtle shadows for depth
- SF Symbols for consistent iconography
- Generous spacing for easy reading

## Technical Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Architecture**: MVVM (Model-View-ViewModel)

### APIs & Frameworks
- **WeatherKit**: Weather forecasts
- **EventKit**: Calendar integration
- **HealthKit**: Step tracking and activity data
- **UserNotifications**: Push notifications
- **WidgetKit**: Home screen widgets (infrastructure ready)

## Project Structure

```
pathwise/
├── Models/                     # Data models
│   ├── WeatherData.swift      # Weather forecast models
│   ├── CalendarData.swift     # Calendar events and free blocks
│   ├── GoldenWindow.swift     # Golden Window model and preferences
│   └── ActivityData.swift     # Health and activity data
│
├── Services/                   # Business logic layer
│   ├── WindowFinderService.swift  # Core algorithm
│   ├── WeatherService.swift       # Weather data fetching
│   ├── CalendarService.swift      # Calendar integration
│   ├── HealthService.swift        # HealthKit integration
│   └── NotificationService.swift  # Push notifications
│
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift       # Main screen
│   │   └── DashboardViewModel.swift  # Dashboard logic
│   └── Components/
│       ├── GoldenWindowCard.swift    # Golden Window display
│       ├── ActivityStatsCard.swift   # Activity metrics
│       ├── WeeklyActivityChart.swift # Weekly bar chart
│       └── WidgetPreview.swift       # Widget designs
│
├── Utils/
│   └── DesignSystem.swift     # Colors, typography, spacing
│
└── Extensions/
    └── WidgetSupport.swift    # Widget infrastructure
```

## Golden Window Algorithm

The app's core logic uses a weighted scoring system (0-100 points):

### Input Parameters
1. **Calendar**: Free time blocks (30+ minutes)
2. **Weather**: Hourly temperature, precipitation, UV index
3. **User Preferences**: Ideal temperature range (60-80°F by default)

### Scoring Breakdown
- **Temperature** (40 points max): Closer to ideal range = higher score
- **Daylight** (30 points max): Peak hours (10 AM - 4 PM) score highest
- **Weather Condition** (20 points max): Clear > Partly Cloudy > Cloudy
- **Precipitation** (10 points max): Lower probability = higher score

### Filtering Rules
The algorithm excludes windows with:
- Rain, snow, or thunderstorms
- Temperature < 30°F or > 90°F
- Precipitation probability > 50%

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- macOS Ventura or later
- iOS 17.0+ device or simulator
- Apple Developer account (for WeatherKit)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/pathwise.git
cd pathwise
```

2. Open the project:
```bash
open pathwise.xcodeproj
```

3. Configure your development team:
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your team

4. Add required capabilities:
   - HealthKit
   - WeatherKit
   - Push Notifications
   - App Groups (for widgets)

5. Update Info.plist with required permission descriptions (see SETUP_GUIDE.md)

6. Build and run (⌘R)

### Development Mode

Phase 1 uses mock data by default for easier development:
- No weather API calls required
- No calendar permission needed
- No HealthKit setup required

To enable real data, see `SETUP_GUIDE.md`.

## Usage

### First Launch
1. App opens to the main dashboard
2. See your Golden Window calculated from mock data
3. View activity stats and weekly progress

### With Real Data
1. Grant calendar, location, and health permissions
2. App analyzes your actual calendar and local weather
3. Receive daily morning notification with your Golden Window
4. Track your walking progress in HealthKit

## Customization

### User Preferences
In `GoldenWindow.swift`, modify `UserPreferences`:
- `preferredWalkDuration`: Default walk length (20 minutes)
- `idealTemperatureMin/Max`: Comfort range (60-80°F)
- `extremeTempMin/Max`: Filter thresholds (30-90°F)
- `dailyStepGoal`: Target steps per day (8000)

### Design System
In `DesignSystem.swift`, customize:
- Brand colors
- Typography styles
- Spacing values
- Corner radius
- Shadow styles

## Future Phases

### Phase 2 (Planned)
- Settings screen for user preferences
- Onboarding flow with permission requests
- Actual Widget Extension implementation
- Background refresh
- Walk tracking during Golden Window
- Historical data analysis

### Phase 3 (Planned)
- Social features (share your walks)
- Custom routes and destinations
- Integration with Apple Maps
- Apple Watch companion app
- Siri shortcuts
- Suggested walking routes

## Testing

### Unit Tests
```bash
# Run tests
cmd+U in Xcode
```

### UI Tests
Currently manual testing. UI tests to be added in Phase 2.

### Mock Data Testing
The app includes comprehensive mock data for testing:
- Mock calendar with 4 events per day
- Mock weather with 24-hour forecast
- Mock health data with weekly history

## Contributing

This is a Phase 1 project. Contributions welcome for:
- Bug fixes
- Algorithm improvements
- UI/UX enhancements
- Documentation updates

## License

Copyright © 2026. All rights reserved.

## Credits

- Design: Following Apple's Human Interface Guidelines
- Icons: SF Symbols
- Weather: Apple WeatherKit
- Inspiration: The need for more intentional walking

---

Built with ❤️ and SwiftUI
