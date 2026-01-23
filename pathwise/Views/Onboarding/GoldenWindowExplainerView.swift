//
//  GoldenWindowExplainerView.swift
//  pathwise
//
//  Visual explanation of how Golden Window works
//

import SwiftUI
import Combine

struct GoldenWindowExplainerView: View {
    @State private var currentStep = 0
    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    private let steps = [
        ExplainerStep(
            icon: "calendar",
            title: "Your Schedule",
            description: "We check your calendar",
            color: .blue
        ),
        ExplainerStep(
            icon: "cloud.sun.fill",
            title: "Weather Data",
            description: "We analyze conditions",
            color: .orange
        ),
        ExplainerStep(
            icon: "sparkles",
            title: "Golden Window",
            description: "We find the perfect time",
            color: Color.accent
        )
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Visual flow
            HStack(spacing: Spacing.md) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    StepCircle(
                        step: step,
                        isActive: index <= currentStep
                    )

                    if index < steps.count - 1 {
                        // Arrow
                        Image(systemName: "arrow.right")
                            .font(.title3)
                            .foregroundColor(
                                index < currentStep ? .accent : .primaryText.opacity(0.3)
                            )
                            .animation(.easeInOut, value: currentStep)
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)

            // Current step description
            VStack(spacing: Spacing.sm) {
                Text(steps[currentStep].title)
                    .font(.pathwiseHeadline)
                    .foregroundColor(.primaryText)
                    .id("title-\(currentStep)")
                    .transition(.opacity)

                Text(steps[currentStep].description)
                    .font(.pathwiseBody)
                    .foregroundColor(.primaryText.opacity(0.7))
                    .id("desc-\(currentStep)")
                    .transition(.opacity)
            }
            .animation(.easeInOut, value: currentStep)
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentStep = (currentStep + 1) % steps.count
            }
        }
    }
}

struct StepCircle: View {
    let step: ExplainerStep
    let isActive: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(isActive ? step.color : Color.primaryText.opacity(0.1))
                    .frame(width: 70, height: 70)

                Image(systemName: step.icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .white : .primaryText.opacity(0.3))
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(isActive ? 1.0 : 0.9)
            .animation(.spring(response: 0.3), value: isActive)
        }
    }
}

struct ExplainerStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    GoldenWindowExplainerView()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
}
