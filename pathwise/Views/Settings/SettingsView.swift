//
//  SettingsView.swift
//  pathwise
//
//  Settings and preferences screen
//

import SwiftUI
import Combine

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var devSettings = DeveloperSettings.shared
    @State private var showingResetAlert = false
    @State private var versionTapCount = 0

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        NavigationView {
            List {
                // Walking Preferences
                Section {
                    HStack {
                        Text("Walk Duration")
                        Spacer()
                        Picker("", selection: $viewModel.walkDuration) {
                            ForEach([15, 20, 25, 30, 45, 60], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.cardBackground)

                    HStack {
                        Text("Daily Step Goal")
                        Spacer()
                        Picker("", selection: $viewModel.stepGoal) {
                            ForEach([5000, 8000, 10000, 12000, 15000], id: \.self) { steps in
                                Text("\(steps)").tag(steps)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.cardBackground)
                } header: {
                    Text("Walking Preferences")
                } footer: {
                    Text("Adjust your preferred walk duration and daily step goal")
                }

                // Walking Hours
                Section {
                    DatePicker("Start Time", selection: $viewModel.walkStartTime, displayedComponents: .hourAndMinute)
                        .listRowBackground(Color.cardBackground)

                    DatePicker("End Time", selection: $viewModel.walkEndTime, displayedComponents: .hourAndMinute)
                        .listRowBackground(Color.cardBackground)
                } header: {
                    Text("Preferred Walking Hours")
                } footer: {
                    Text("Only suggest walks within this time range")
                }

                // Temperature Preferences
                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Ideal Temperature Range")
                            .font(.pathwiseBody)

                        HStack {
                            Text("\(Int(viewModel.idealTempMin))°F")
                                .font(.pathwiseCaption)
                                .frame(width: 50, alignment: .leading)

                            VStack(spacing: 4) {
                                RangeSlider(
                                    minValue: $viewModel.idealTempMin,
                                    maxValue: $viewModel.idealTempMax,
                                    bounds: 30...100
                                )

                                HStack {
                                    Text("30°F")
                                        .font(.pathwiseCaption)
                                        .foregroundColor(.primaryText.opacity(0.5))
                                    Spacer()
                                    Text("100°F")
                                        .font(.pathwiseCaption)
                                        .foregroundColor(.primaryText.opacity(0.5))
                                }
                            }

                            Text("\(Int(viewModel.idealTempMax))°F")
                                .font(.pathwiseCaption)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                    .listRowBackground(Color.cardBackground)
                } header: {
                    Text("Comfort Zone")
                } footer: {
                    Text("Your preferred temperature range for walking")
                }

                // Theme Preferences
                Section {
                    Picker("Appearance", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.cardBackground)

                    if viewModel.theme == .dark || (viewModel.theme == .system && isDarkMode) {
                        Picker("Dark Mode Style", selection: $viewModel.darkModeStyle) {
                            ForEach(DarkModeStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.cardBackground)
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    if viewModel.theme == .dark || (viewModel.theme == .system && isDarkMode) {
                        Text("Choose between light, dark, or system theme. Default uses deep blue, Black uses pure black.")
                    } else {
                        Text("Choose between light, dark, or system theme")
                    }
                }

                // Notification Preferences
                Section {
                    Toggle("Daily Nudge", isOn: $viewModel.notificationsEnabled)
                        .listRowBackground(Color.cardBackground)

                    if viewModel.notificationsEnabled {
                        DatePicker(
                            "Notification Time",
                            selection: $viewModel.notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .listRowBackground(Color.cardBackground)

                        Toggle("Window Reminder", isOn: $viewModel.windowReminderEnabled)
                            .disabled(!viewModel.notificationsEnabled)
                            .listRowBackground(Color.cardBackground)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get daily reminders about your Golden Window")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.primaryText.opacity(0.5))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        versionTapCount += 1
                        if versionTapCount >= 3 {
                            devSettings.toggleDevMenu()
                            versionTapCount = 0
                        }
                        // Reset counter after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            versionTapCount = 0
                        }
                    }
                    .listRowBackground(Color.cardBackground)

                    Button("Reset Onboarding") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    .listRowBackground(Color.cardBackground)
                } header: {
                    Text("About")
                }

                // Developer Menu (hidden unless enabled)
                if devSettings.isEnabled {
                    Section {
                        Toggle("Enable Dev Menu", isOn: $devSettings.isEnabled)
                            .foregroundColor(.orange)
                            .listRowBackground(Color.cardBackground)

                        Picker("Mock Scenario", selection: $devSettings.currentScenario) {
                            ForEach(MockScenario.allCases) { scenario in
                                Text(scenario.rawValue).tag(scenario)
                            }
                        }
                        .listRowBackground(Color.cardBackground)

                        Text("Triple-tap version number to toggle dev menu")
                            .font(.pathwiseCaption)
                            .foregroundColor(.primaryText.opacity(0.5))
                            .listRowBackground(Color.cardBackground)
                    } header: {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.orange)
                            Text("Developer")
                                .foregroundColor(.orange)
                        }
                    } footer: {
                        Text("Test different window scenarios. This menu is for development only.")
                            .foregroundColor(.orange.opacity(0.7))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.accent)
                }
            }
            .onChange(of: viewModel.walkDuration) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.stepGoal) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.walkStartTime) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.walkEndTime) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.idealTempMin) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.idealTempMax) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.theme) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.darkModeStyle) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.notificationsEnabled) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.notificationTime) { _, _ in viewModel.savePreferences() }
            .onChange(of: viewModel.windowReminderEnabled) { _, _ in viewModel.savePreferences() }
            .onChange(of: devSettings.currentScenario) { _, _ in
                // Trigger refresh when dev scenario changes
                NotificationCenter.default.post(name: .devScenarioChanged, object: nil)
            }
            .alert("Reset Onboarding", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetOnboarding()
                    dismiss()
                }
            } message: {
                Text("This will show the onboarding screens again when you relaunch the app.")
            }
            .scrollContentBackground(.hidden)
            .background(Color.primaryBackground)
        }
        .preferredColorScheme(themeManager.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
            themeManager.updateTheme()
        }
    }
}

// MARK: - Range Slider Component
struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>

    @State private var activeThumb: Thumb?

    enum Thumb {
        case min, max
    }

    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width

            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)

                // Active range
                let minPosition = sliderWidth * CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
                let maxPosition = sliderWidth * CGFloat((maxValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))

                Rectangle()
                    .fill(Color.accent)
                    .frame(
                        width: max(0, maxPosition - minPosition),
                        height: 4
                    )
                    .offset(x: minPosition)
                    .cornerRadius(2)

                // Min thumb
                Circle()
                    .fill(Color.accent)
                    .frame(width: 20, height: 20)
                    .offset(x: sliderWidth * CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) - 10)

                // Max thumb
                Circle()
                    .fill(Color.accent)
                    .frame(width: 20, height: 20)
                    .offset(x: sliderWidth * CGFloat((maxValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) - 10)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Calculate the new value based on touch location
                        let touchX = max(0, min(value.location.x, sliderWidth))
                        let percent = Double(touchX / sliderWidth)
                        let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * percent

                        // On first touch, determine which thumb to move based on start location
                        if activeThumb == nil {
                            let minThumbX = sliderWidth * CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
                            let maxThumbX = sliderWidth * CGFloat((maxValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))

                            if abs(value.startLocation.x - minThumbX) < abs(value.startLocation.x - maxThumbX) {
                                activeThumb = .min
                            } else {
                                activeThumb = .max
                            }
                        }

                        // Move the active thumb
                        if activeThumb == .min {
                            minValue = min(max(bounds.lowerBound, newValue), maxValue - 5)
                        } else if activeThumb == .max {
                            maxValue = max(min(bounds.upperBound, newValue), minValue + 5)
                        }
                    }
                    .onEnded { _ in
                        activeThumb = nil
                    }
            )
        }
        .frame(height: 20)
    }
}

// MARK: - View Model
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var walkDuration: Int
    @Published var stepGoal: Int
    @Published var walkStartTime: Date
    @Published var walkEndTime: Date
    @Published var idealTempMin: Double
    @Published var idealTempMax: Double
    @Published var theme: AppTheme
    @Published var darkModeStyle: DarkModeStyle
    @Published var notificationsEnabled: Bool
    @Published var notificationTime: Date
    @Published var windowReminderEnabled: Bool

    private var preferences: UserPreferences

    init() {
        // Load from UserDefaults or use defaults
        self.preferences = SettingsViewModel.loadPreferences()

        self.walkDuration = preferences.preferredWalkDuration
        self.stepGoal = preferences.dailyStepGoal
        self.walkStartTime = preferences.preferredWalkStartTime
        self.walkEndTime = preferences.preferredWalkEndTime
        self.idealTempMin = preferences.idealTemperatureMin
        self.idealTempMax = preferences.idealTemperatureMax
        self.theme = preferences.theme
        self.darkModeStyle = preferences.darkModeStyle
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.notificationTime = preferences.morningNotificationTime
        self.windowReminderEnabled = UserDefaults.standard.bool(forKey: "windowReminderEnabled")
    }

    func savePreferences() {
        preferences.preferredWalkDuration = walkDuration
        preferences.dailyStepGoal = stepGoal
        preferences.preferredWalkStartTime = walkStartTime
        preferences.preferredWalkEndTime = walkEndTime
        preferences.idealTemperatureMin = idealTempMin
        preferences.idealTemperatureMax = idealTempMax
        preferences.theme = theme
        preferences.darkModeStyle = darkModeStyle
        preferences.morningNotificationTime = notificationTime

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "userPreferences")
        }

        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(windowReminderEnabled, forKey: "windowReminderEnabled")

        // Notify that theme changed
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    static func loadPreferences() -> UserPreferences {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return preferences
        }
        return UserPreferences()
    }
}

#Preview {
    SettingsView()
}
