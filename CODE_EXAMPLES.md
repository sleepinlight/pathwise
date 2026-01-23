# Pathwise - Code Examples & Patterns

Quick reference guide for common patterns and examples used in Pathwise.

## Table of Contents
1. [Using the Services](#using-the-services)
2. [Customizing the Algorithm](#customizing-the-algorithm)
3. [Adding New UI Components](#adding-new-ui-components)
4. [Working with Mock Data](#working-with-mock-data)
5. [Implementing Real Data](#implementing-real-data)
6. [Scheduling Notifications](#scheduling-notifications)
7. [Design System Usage](#design-system-usage)

---

## Using the Services

### Weather Service
```swift
// Initialize
let weatherService = WeatherService()

// Fetch real weather
await weatherService.fetchWeather(for: userLocation)

// Use mock weather
weatherService.fetchMockWeather()

// Access forecast
let forecast = weatherService.currentForecast // [HourlyWeather]
```

### Calendar Service
```swift
// Initialize
let calendarService = CalendarService()

// Request permission
let granted = await calendarService.requestCalendarAccess()

// Fetch today's events
await calendarService.fetchTodayEvents()

// Access free blocks
let freeTime = calendarService.freeBlocks // [FreeTimeBlock]

// Use mock calendar
calendarService.useMockCalendar()
```

### Health Service
```swift
// Initialize
let healthService = HealthService()

// Request permission
let granted = await healthService.requestHealthAccess()

// Fetch today's activity
await healthService.fetchTodayActivity()

// Access data
let steps = healthService.todaySteps
let distance = healthService.todayDistance
let minutes = healthService.todayMinutesMoved

// Use mock health data
healthService.useMockHealthData()
```

### Window Finder Service
```swift
// Initialize with preferences
let preferences = UserPreferences()
let windowFinder = WindowFinderService(preferences: preferences)

// Find Golden Window
let goldenWindow = windowFinder.findGoldenWindow(
    freeBlocks: calendarService.freeBlocks,
    weatherForecast: weatherService.currentForecast,
    lookAheadHours: 12
)

if let window = goldenWindow {
    print("Found Golden Window at \(window.timeString)")
    print("Score: \(window.score)")
    print("Weather: \(Int(window.weather.temperature))°F")
}
```

---

## Customizing the Algorithm

### Change Temperature Preferences
```swift
var preferences = UserPreferences()
preferences.idealTemperatureMin = 65.0  // Lower bound
preferences.idealTemperatureMax = 75.0  // Upper bound
preferences.extremeTempMin = 40.0       // Filter threshold
preferences.extremeTempMax = 85.0       // Filter threshold
```

### Adjust Walk Duration
```swift
var preferences = UserPreferences()
preferences.preferredWalkDuration = 30  // 30 minutes instead of 20
```

### Modify Step Goal
```swift
var preferences = UserPreferences()
preferences.dailyStepGoal = 10000  // Increase from 8000
```

### Change Notification Time
```swift
var preferences = UserPreferences()
let calendar = Calendar.current
preferences.morningNotificationTime = calendar.date(
    from: DateComponents(hour: 7, minute: 0)
)!  // 7:00 AM instead of 8:30 AM
```

### Adjust Scoring Weights
In `WindowFinderService.swift`, modify the scoring methods:

```swift
private func calculateTemperatureScore(_ temp: Double) -> Double {
    // Change max points from 40 to 50
    if preferences.isTemperatureIdeal(temp) {
        return 50.0  // Was 40.0
    }
    // ... rest of method
}

private func calculateDaylightScore(_ time: Date) -> Double {
    // Adjust scoring for different hours
    let hour = Calendar.current.component(.hour, from: time)

    // Custom schedule for night owls
    if hour >= 12 && hour < 18 {
        return 30.0  // Afternoon preferred
    } else if hour >= 18 && hour < 20 {
        return 25.0  // Evening still good
    }
    // ... rest of scoring
}
```

---

## Adding New UI Components

### Create a New Card Component
```swift
import SwiftUI

struct CustomCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.accent)

                Text(title)
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Spacer()
            }

            // Content
            Text(value)
                .font(.pathwiseLargeNumber)
                .foregroundColor(.accent)
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

// Usage in DashboardView
CustomCard(title: "Custom Metric", value: "42")
    .padding(.horizontal, Spacing.lg)
```

### Add to Dashboard
In `DashboardView.swift`:
```swift
ScrollView {
    VStack(spacing: Spacing.lg) {
        // ... existing cards

        // Add your new component
        CustomCard(title: "New Feature", value: "Value")
            .padding(.horizontal, Spacing.lg)
    }
}
```

---

## Working with Mock Data

### Generate Custom Mock Weather
```swift
extension WeatherService {
    func fetchCustomMockWeather(baseTemp: Double, condition: WeatherCondition) {
        let now = Date()
        var mockForecasts: [HourlyWeather] = []

        for hour in 0..<24 {
            let time = Calendar.current.date(byAdding: .hour, value: hour, to: now)!

            mockForecasts.append(HourlyWeather(
                time: time,
                temperature: baseTemp + Double.random(in: -5...5),
                precipitationProbability: 0.1,
                uvIndex: 5,
                weatherCondition: condition
            ))
        }

        currentForecast = mockForecasts
    }
}

// Usage
weatherService.fetchCustomMockWeather(baseTemp: 70, condition: .clear)
```

### Create Custom Mock Calendar
```swift
extension CalendarService {
    func createCustomMockEvents(busyHours: [Int]) {
        let calendar = Calendar.current
        let now = Date()

        let mockEvents = busyHours.map { hour in
            CalendarEvent(
                title: "Meeting",
                startTime: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)!,
                endTime: calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: now)!,
                isAllDay: false
            )
        }

        self.events = mockEvents
        self.freeBlocks = calculateFreeBlocks(from: mockEvents)
    }
}

// Usage - busy at 9 AM, 1 PM, and 3 PM
calendarService.createCustomMockEvents(busyHours: [9, 13, 15])
```

---

## Implementing Real Data

### Switch ViewModel to Real Data
In `DashboardViewModel.swift`:

```swift
func initialize() async {
    isLoading = true

    // Comment out mock data
    // await loadMockData()

    // Enable real data
    await loadRealData()

    calculateGoldenWindow()
    isLoading = false
}

private func loadRealData() async {
    // Request permissions
    async let calendarAccess = calendarService.requestCalendarAccess()
    async let healthAccess = healthService.requestHealthAccess()

    let (hasCalendar, hasHealth) = await (calendarAccess, healthAccess)

    guard hasCalendar && hasHealth else {
        print("Permissions denied")
        return
    }

    // Get user's location for weather
    // (You'll need to add LocationService)
    // let location = await locationService.getCurrentLocation()

    // Fetch all data concurrently
    async let calendar = calendarService.fetchTodayEvents()
    // async let weather = weatherService.fetchWeather(for: location)
    async let todayActivity = healthService.fetchTodayActivity()
    async let weeklyActivity = healthService.fetchWeeklyActivity()

    await (calendar, todayActivity, weeklyActivity)

    // Update published properties
    self.todaySteps = healthService.todaySteps
    self.todayDistance = healthService.todayDistance
    self.todayMinutes = healthService.todayMinutesMoved
    self.weeklyActivities = healthService.weeklyActivities
}
```

### Add Location Service (for Weather)
Create `LocationService.swift`:

```swift
import CoreLocation

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
```

---

## Scheduling Notifications

### Schedule Daily Nudge
```swift
let notificationService = NotificationService.shared

// Request permission first
let granted = await notificationService.requestAuthorization()

guard granted else {
    print("Notification permission denied")
    return
}

// Schedule for your Golden Window
if let window = goldenWindow {
    let preferences = UserPreferences()
    notificationService.scheduleDailyNudge(
        for: window,
        notificationTime: preferences.morningNotificationTime
    )
}
```

### Schedule Window Reminder
```swift
// Remind user 15 minutes before their Golden Window
if let window = goldenWindow {
    notificationService.scheduleWindowReminder(
        for: window,
        minutesBefore: 15
    )
}
```

### Cancel Notifications
```swift
// Cancel all
notificationService.cancelAllNotifications()

// Cancel specific
notificationService.cancelDailyNudge()
notificationService.cancelWindowReminder()
```

---

## Design System Usage

### Using Brand Colors
```swift
// In any SwiftUI view
Text("Hello")
    .foregroundColor(.accent)           // Sage Green
    .background(Color.primaryBackground) // Cream

Circle()
    .fill(Color.primaryText)            // Slate Blue

RoundedRectangle(cornerRadius: 12)
    .fill(Color.cardBackground)         // White
```

### Using Typography
```swift
Text("Title")
    .font(.pathwiseTitle)           // Large, bold

Text("Heading")
    .font(.pathwiseHeadline)        // Medium, semibold

Text("Subheading")
    .font(.pathwiseSubheadline)     // Smaller, medium

Text("Body")
    .font(.pathwiseBody)            // Regular text

Text("Caption")
    .font(.pathwiseCaption)         // Small text

Text("72")
    .font(.pathwiseLargeNumber)     // Big numbers
```

### Using Spacing
```swift
VStack(spacing: Spacing.lg) {      // 24pt spacing
    Text("First")
    Text("Second")
}

HStack(spacing: Spacing.md) {      // 16pt spacing
    Image(systemName: "star")
    Text("Rating")
}

.padding(Spacing.xl)               // 32pt padding
.padding(.horizontal, Spacing.sm)  // 8pt horizontal padding
```

### Using Corner Radius
```swift
RoundedRectangle(cornerRadius: CornerRadius.lg)  // 16pt
RoundedRectangle(cornerRadius: CornerRadius.md)  // 12pt
RoundedRectangle(cornerRadius: CornerRadius.sm)  // 8pt

// Or on any view
SomeView()
    .cornerRadius(CornerRadius.lg)
```

### Using Shadows
```swift
// Card shadow (more prominent)
CardView()
    .pathwiseCardShadow()

// Light shadow (subtle)
SmallComponent()
    .pathwiseLightShadow()
```

### Creating Custom Colors
```swift
// Add to DesignSystem.swift
extension Color {
    static let customAccent = Color(hex: "#FF5733")
    static let customBackground = Color(hex: "#F0F0F0")
}

// Usage
Text("Custom")
    .foregroundColor(.customAccent)
```

---

## Common Patterns

### Async Loading Pattern
```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                ContentView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
```

### Error Handling Pattern
```swift
@Published var error: Error?
@Published var showError = false

func fetchData() async {
    do {
        let data = try await service.fetch()
        // Process data
    } catch {
        await MainActor.run {
            self.error = error
            self.showError = true
        }
    }
}

// In view
.alert("Error", isPresented: $viewModel.showError) {
    Button("OK") { }
} message: {
    Text(viewModel.error?.localizedDescription ?? "Unknown error")
}
```

### Refresh Pattern
```swift
// In view
.refreshable {
    await viewModel.refresh()
}

// In viewModel
func refresh() async {
    isLoading = true
    await loadData()
    calculateResults()
    isLoading = false
}
```

---

## Tips & Best Practices

### 1. Always use MainActor for UI updates
```swift
await MainActor.run {
    self.isLoading = false
    self.data = newData
}
```

### 2. Use async let for concurrent operations
```swift
async let weather = fetchWeather()
async let calendar = fetchCalendar()
async let health = fetchHealth()

let (w, c, h) = await (weather, calendar, health)
```

### 3. Provide sensible defaults
```swift
var steps: Int = 0  // Not optional, default to 0
var window: GoldenWindow?  // Optional when might not exist
```

### 4. Use computed properties for derived data
```swift
var stepProgress: Double {
    min(Double(steps) / Double(goal), 1.0)
}
```

### 5. Keep views simple, logic in ViewModels
```swift
// ❌ Bad - logic in view
var body: some View {
    let progress = min(Double(steps) / Double(goal), 1.0)
    ProgressView(value: progress)
}

// ✅ Good - logic in viewModel
var body: some View {
    ProgressView(value: viewModel.stepProgress)
}
```

---

For more examples, see the actual implementation files in the project.
