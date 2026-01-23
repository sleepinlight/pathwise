//
//  OnboardingView.swift
//  pathwise
//
//  Main onboarding flow
//

import SwiftUI
import Combine

struct OnboardingView: View {
    @StateObject private var onboardingState = OnboardingState()
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        ZStack {
            Color.primaryBackground
                .ignoresSafeArea()

            TabView(selection: $onboardingState.currentPage) {
                ForEach(Array(OnboardingPage.allCases.enumerated()), id: \.element) { index, page in
                    OnboardingPageView(
                        page: page,
                        isLastPage: index == OnboardingPage.allCases.count - 1,
                        onComplete: {
                            onboardingState.completeOnboarding()
                            isOnboardingComplete = true
                        },
                        onNext: {
                            withAnimation {
                                onboardingState.currentPage = min(
                                    index + 1,
                                    OnboardingPage.allCases.count - 1
                                )
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let onComplete: () -> Void
    let onNext: () -> Void

    @StateObject private var permissionManager = PermissionManager()

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: page.iconName)
                .font(.system(size: 80))
                .foregroundColor(.accent)
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, Spacing.lg)

            // Title
            Text(page.title)
                .font(.pathwiseTitle)
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            // Subtitle
            Text(page.subtitle)
                .font(.pathwiseBody)
                .foregroundColor(.primaryText.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Permission-specific content
            if page.requiresPermission {
                PermissionCard(
                    page: page,
                    permissionManager: permissionManager,
                    onGranted: onNext
                )
                .padding(.horizontal, Spacing.lg)
            }

            // Action Button
            if !page.requiresPermission {
                Button(action: {
                    if isLastPage {
                        onComplete()
                    } else {
                        onNext()
                    }
                }) {
                    Text(isLastPage ? "Get Started" : "Continue")
                        .font(.pathwiseSubheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.accent)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal, Spacing.lg)
            }

            // Skip option (not on last page)
            if !isLastPage && page.requiresPermission {
                Button(action: onNext) {
                    Text("Skip for now")
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText.opacity(0.5))
                }
                .padding(.top, Spacing.sm)
            }

            Spacer()
                .frame(height: Spacing.xxl)
        }
    }
}

struct PermissionCard: View {
    let page: OnboardingPage
    @ObservedObject var permissionManager: PermissionManager
    let onGranted: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Permission details
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(permissionDetails, id: \.self) { detail in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.accent)
                            .padding(.top, 2)

                        Text(detail)
                            .font(.pathwiseBody)
                            .foregroundColor(.primaryText.opacity(0.8))
                    }
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.md)
            .pathwiseLightShadow()

            // Request button
            Button(action: {
                requestPermission()
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(buttonText)
                            .font(.pathwiseSubheadline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(permissionGranted ? Color.green : Color.accent)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(isRequesting || permissionGranted)
        }
    }

    private var permissionDetails: [String] {
        switch page {
        case .calendar:
            return [
                "Find free time blocks in your schedule",
                "Never interrupts your meetings or events",
                "Works with all your calendar apps"
            ]
        case .weather:
            return [
                "Check real-time weather conditions",
                "Avoid rain, extreme heat, or cold",
                "Find the most comfortable walking times"
            ]
        case .health:
            return [
                "Track your daily steps and distance",
                "See your walking progress over time",
                "Celebrate your walking streaks"
            ]
        case .notifications:
            return [
                "Get a morning reminder about your Golden Window",
                "Optional reminders before your walk time",
                "You control when and how often"
            ]
        default:
            return []
        }
    }

    private var buttonText: String {
        if permissionGranted {
            return "✓ Granted"
        }
        switch page {
        case .calendar:
            return "Allow Calendar Access"
        case .weather:
            return "Allow Location Access"
        case .health:
            return "Allow Health Access"
        case .notifications:
            return "Allow Notifications"
        default:
            return "Allow Access"
        }
    }

    private var permissionGranted: Bool {
        switch page {
        case .calendar:
            return permissionManager.calendarGranted
        case .weather:
            return permissionManager.locationGranted
        case .health:
            return permissionManager.healthGranted
        case .notifications:
            return permissionManager.notificationsGranted
        default:
            return false
        }
    }

    private func requestPermission() {
        isRequesting = true

        Task {
            let granted = await permissionManager.requestPermission(for: page)

            await MainActor.run {
                isRequesting = false
                if granted {
                    // Wait a moment to show success state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onGranted()
                    }
                }
            }
        }
    }
}

// MARK: - Permission Manager
@MainActor
class PermissionManager: ObservableObject {
    @Published var calendarGranted = false
    @Published var locationGranted = false
    @Published var healthGranted = false
    @Published var notificationsGranted = false

    private let calendarService = CalendarService()
    private let healthService = HealthService()
    private let notificationService = NotificationService.shared

    func requestPermission(for page: OnboardingPage) async -> Bool {
        switch page {
        case .calendar:
            let granted = await calendarService.requestCalendarAccess()
            calendarGranted = granted
            return granted

        case .weather:
            // Location permission for weather
            // For now, we'll just mark as granted since we're using mock data
            // In production, you'd request location permission here
            locationGranted = true
            return true

        case .health:
            let granted = await healthService.requestHealthAccess()
            healthGranted = granted
            return granted

        case .notifications:
            let granted = await notificationService.requestAuthorization()
            notificationsGranted = granted
            return granted

        default:
            return true
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
