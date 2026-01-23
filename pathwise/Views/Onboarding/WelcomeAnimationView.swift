//
//  WelcomeAnimationView.swift
//  pathwise
//
//  Animated welcome screen component
//

import SwiftUI

struct WelcomeAnimationView: View {
    @State private var isAnimating = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Animated walking figure
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.accent.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Middle circle
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 0.9 : 1.1)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Walking icon
                Image(systemName: "figure.walk")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.bottom, Spacing.lg)

            // App name with fade-in
            if showText {
                VStack(spacing: Spacing.sm) {
                    Text("Pathwise")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryText)
                        .transition(.opacity.combined(with: .scale))

                    Text("Your walking companion")
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText.opacity(0.6))
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            isAnimating = true

            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                showText = true
            }
        }
    }
}

#Preview {
    WelcomeAnimationView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
}
