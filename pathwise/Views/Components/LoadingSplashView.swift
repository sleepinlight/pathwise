//
//  LoadingSplashView.swift
//  pathwise
//
//  Loading splash screen shown while dashboard initializes
//

import SwiftUI

struct LoadingSplashView: View {
    @State private var isAnimating = false
    @AppStorage("dynamicBackgroundEnabled") private var dynamicBackgroundEnabled: Bool = true

    var body: some View {
        ZStack {
            // Background
            if dynamicBackgroundEnabled {
                DynamicBackgroundView()
            } else {
                Color.primaryBackground.ignoresSafeArea()
            }

            // Content
            VStack(spacing: Spacing.xl) {
                Spacer()

                // App icon/logo
                Image("SplashIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )

                // Text
                Text("Let's Get Moving")
                    .font(.pathwiseTitle)
                    .foregroundColor(.primaryText)
                    .opacity(isAnimating ? 1.0 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Spacer()

                // Loading indicator
                ProgressView()
                    .tint(.primaryText)
                    .scaleEffect(1.2)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingSplashView()
}
