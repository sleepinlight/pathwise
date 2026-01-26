//
//  PathsView.swift
//  pathwise
//
//  Paths feature - Coming Soon
//

import SwiftUI

struct PathsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Map Icon
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accent)
                }

                // Title
                Text("Paths")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryText)

                // Coming Soon Badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondaryAccent)

                    Text("Coming Soon")
                        .font(.pathwiseSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondaryAccent)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.secondaryAccent.opacity(0.15))
                .cornerRadius(CornerRadius.md)

                // Description
                Text("Discover and save your favorite walking routes")
                    .font(.pathwiseBody)
                    .foregroundColor(.primaryText.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    PathsView()
}
