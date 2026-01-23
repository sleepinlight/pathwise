# Pathwise Onboarding Guide

## Overview

Pathwise includes a comprehensive onboarding flow that educates users about the app's value proposition while gracefully requesting necessary permissions.

## Onboarding Flow

### Page 1: Welcome
- **Visual**: Animated walking figure with pulsing circles
- **Message**: "Welcome to Pathwise - Your proactive walking concierge"
- **Purpose**: Set friendly, welcoming tone
- **Action**: Continue button

### Page 2: How It Works
- **Visual**: Animated explainer showing the flow: Calendar → Weather → Golden Window
- **Message**: "Find Your Golden Window"
- **Description**: "We analyze your schedule and weather to find the perfect time for a walk"
- **Purpose**: Explain core value proposition
- **Action**: Continue button

### Page 3: Calendar Permission
- **Visual**: Calendar icon
- **Message**: "Connect Your Calendar"
- **Benefits Shown**:
  - Find free time blocks in your schedule
  - Never interrupts your meetings or events
  - Works with all your calendar apps
- **Purpose**: Request calendar access
- **Action**: "Allow Calendar Access" button or "Skip for now"

### Page 4: Weather/Location Permission
- **Visual**: Weather icon (cloud with sun)
- **Message**: "Check the Weather"
- **Benefits Shown**:
  - Check real-time weather conditions
  - Avoid rain, extreme heat, or cold
  - Find the most comfortable walking times
- **Purpose**: Request location access for weather
- **Action**: "Allow Location Access" button or "Skip for now"

### Page 5: Health Permission
- **Visual**: Heart icon
- **Message**: "Track Your Progress"
- **Benefits Shown**:
  - Track your daily steps and distance
  - See your walking progress over time
  - Celebrate your walking streaks
- **Purpose**: Request HealthKit access
- **Action**: "Allow Health Access" button or "Skip for now"

### Page 6: Notifications Permission
- **Visual**: Bell icon
- **Message**: "Get Daily Nudges"
- **Benefits Shown**:
  - Get a morning reminder about your Golden Window
  - Optional reminders before your walk time
  - You control when and how often
- **Purpose**: Request notification permission
- **Action**: "Allow Notifications" button or "Skip for now"

### Page 7: Ready to Go
- **Visual**: Checkmark icon
- **Message**: "You're All Set!"
- **Description**: "Let's find your first Golden Window"
- **Purpose**: Completion and excitement
- **Action**: "Get Started" button → Dashboard

## Design Principles

### 1. Value First, Permission Second
Each permission request is preceded by clear explanation of the benefit to the user.

### 2. Non-Blocking
Users can skip any permission and still use the app with mock data or reduced functionality.

### 3. Visual Consistency
- Brand colors (Sage Green, Cream, Slate Blue)
- Rounded, friendly typography
- Generous spacing
- Smooth animations

### 4. Progress Indication
- Page dots show progress through onboarding
- Swipeable pages for easy navigation
- Can also tap "Continue" buttons

### 5. One Permission Per Page
Never overwhelm with multiple permission requests simultaneously.

## Technical Implementation

### OnboardingState
Manages onboarding completion state:
```swift
class OnboardingState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var currentPage: Int
}
```

Stored in `UserDefaults` with key: `hasCompletedOnboarding`

### PermissionManager
Coordinates permission requests:
- Calendar (EventKit)
- Location (CoreLocation) - for weather
- Health (HealthKit)
- Notifications (UserNotifications)

### Flow Control
1. App launches → Check `hasCompletedOnboarding`
2. If `false` → Show OnboardingView
3. If `true` → Show DashboardView
4. After completing onboarding → Set `hasCompletedOnboarding = true`

## Permission States

### Calendar
- **Granted**: Full calendar integration, real free time blocks
- **Denied/Not Determined**: Mock calendar with simulated events

### Location/Weather
- **Granted**: Real-time weather based on user's location
- **Denied**: Mock weather data (still functional)

### Health
- **Granted**: Real step count, distance, exercise minutes
- **Denied**: Mock health data for demonstration

### Notifications
- **Granted**: Daily nudge and window reminders
- **Denied**: No notifications (app still fully functional)

## Settings Integration

Users can:
- Reset onboarding (Settings → "Reset Onboarding")
- Adjust preferences without re-requesting permissions
- Change notification settings

### Resetting Onboarding
```swift
UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
```

App will show onboarding again on next launch.

## User Experience Features

### Animations
- **Welcome page**: Pulsing circles around walking icon
- **How It Works**: Animated flow diagram
- **Permission pages**: Success state when permission granted
- **Transitions**: Smooth page changes

### Visual Feedback
- ✓ Checkmark when permission granted
- Green button background on success
- Progress indicators during permission request
- Disabled state for granted permissions

### Skip Options
- All permission pages have "Skip for now" button
- Allows users to complete onboarding without granting all permissions
- Can grant permissions later through iOS Settings

## Accessibility

### VoiceOver Support
- All icons have descriptive labels
- Button purposes clearly stated
- Progress indication announced

### Dynamic Type
- All text uses system fonts
- Scales with user's preferred text size
- Maintains readability at all sizes

### Color Contrast
- Meets WCAG AA standards
- Text readable against all backgrounds
- Accent color (Sage Green) tested for visibility

## Testing Onboarding

### During Development
1. Delete app from simulator/device
2. Reinstall and launch
3. Onboarding shows automatically

### Reset Onboarding
1. Open Settings in app
2. Tap "Reset Onboarding"
3. Close and relaunch app

### Or Manually
```swift
UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
```

## Best Practices

### Do's
✅ Explain "why" before requesting permission
✅ Show specific benefits to the user
✅ Allow skipping without breaking the app
✅ Make it beautiful and engaging
✅ Keep text concise and friendly
✅ Animate to delight users

### Don'ts
❌ Request all permissions at once
❌ Use technical jargon
❌ Make permissions mandatory
❌ Show alerts without context
❌ Rush through explanation
❌ Block app usage without permissions

## Permission Request Timing

### First Launch
All permission requests happen during onboarding in logical order:
1. Calendar (for scheduling)
2. Weather (for conditions)
3. Health (for tracking)
4. Notifications (for reminders)

### Subsequent Launches
- No permission requests if already granted
- If denied, app works with mock data
- Users can grant later through iOS Settings

### In-App Permission Changes
Settings screen allows users to:
- See permission status
- Open iOS Settings to change permissions
- Understand what each permission enables

## Metrics to Track

Consider tracking:
- Completion rate (what % complete onboarding)
- Permission grant rates per type
- Drop-off points (which page users abandon)
- Skip rates per permission
- Time spent in onboarding

## Localization Ready

All strings are in code (not hardcoded in UI):
```swift
var title: String {
    switch self {
    case .welcome:
        return "Welcome to Pathwise"
    // ...
    }
}
```

Ready for localization in future versions.

## Files Structure

```
Views/Onboarding/
├── OnboardingView.swift              # Main onboarding coordinator
├── WelcomeAnimationView.swift        # Welcome page animation
└── GoldenWindowExplainerView.swift   # How it works animation

Models/
└── OnboardingState.swift             # State management

Views/Settings/
└── SettingsView.swift                # Includes reset onboarding
```

## Future Enhancements

Consider adding:
- Tutorial tooltips on first dashboard view
- Interactive demo of finding a Golden Window
- Video walkthrough option
- Personalization questions (morning person vs night owl)
- Walk duration preferences during onboarding
- Temperature preferences during onboarding

---

**The onboarding flow is complete and ready to use!** 🎉

Users will have a delightful first experience that educates and requests permissions gracefully.
