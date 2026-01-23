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
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetAlert = false

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
                } header: {
                    Text("Walking Preferences")
                } footer: {
                    Text("Adjust your preferred walk duration and daily step goal")
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
                } header: {
                    Text("Comfort Zone")
                } footer: {
                    Text("Your preferred temperature range for walking")
                }

                // Notification Preferences
                Section {
                    Toggle("Daily Nudge", isOn: $viewModel.notificationsEnabled)

                    if viewModel.notificationsEnabled {
                        DatePicker(
                            "Notification Time",
                            selection: $viewModel.notificationTime,
                            displayedComponents: .hourAndMinute
                        )

                        Toggle("Window Reminder", isOn: $viewModel.windowReminderEnabled)
                            .disabled(!viewModel.notificationsEnabled)
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

                    Button("Reset Onboarding") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.savePreferences()
                        dismiss()
                    }
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.accent)
                }
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
        }
    }
}

// MARK: - Range Slider Component
struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)

                // Active range
                Rectangle()
                    .fill(Color.accent)
                    .frame(
                        width: max(0, geometry.size.width * CGFloat((maxValue - minValue) / (bounds.upperBound - bounds.lowerBound))),
                        height: 4
                    )
                    .offset(x: geometry.size.width * CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)))
                    .cornerRadius(2)
            }
        }
        .frame(height: 20)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let percent = Double(value.location.x / UIScreen.main.bounds.width * 0.8)
                    let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * percent

                    // Determine which thumb to move
                    if abs(newValue - minValue) < abs(newValue - maxValue) {
                        minValue = min(max(bounds.lowerBound, newValue), maxValue - 5)
                    } else {
                        maxValue = max(min(bounds.upperBound, newValue), minValue + 5)
                    }
                }
        )
    }
}

// MARK: - View Model
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var walkDuration: Int
    @Published var stepGoal: Int
    @Published var idealTempMin: Double
    @Published var idealTempMax: Double
    @Published var notificationsEnabled: Bool
    @Published var notificationTime: Date
    @Published var windowReminderEnabled: Bool

    private var preferences: UserPreferences

    init() {
        // Load from UserDefaults or use defaults
        self.preferences = SettingsViewModel.loadPreferences()

        self.walkDuration = preferences.preferredWalkDuration
        self.stepGoal = preferences.dailyStepGoal
        self.idealTempMin = preferences.idealTemperatureMin
        self.idealTempMax = preferences.idealTemperatureMax
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.notificationTime = preferences.morningNotificationTime
        self.windowReminderEnabled = UserDefaults.standard.bool(forKey: "windowReminderEnabled")
    }

    func savePreferences() {
        preferences.preferredWalkDuration = walkDuration
        preferences.dailyStepGoal = stepGoal
        preferences.idealTemperatureMin = idealTempMin
        preferences.idealTemperatureMax = idealTempMax
        preferences.morningNotificationTime = notificationTime

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "userPreferences")
        }

        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(windowReminderEnabled, forKey: "windowReminderEnabled")
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
