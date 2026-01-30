//
//  MainTabView.swift
//  pathwise
//
//  Main tab bar navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard
        case trends
        case paths
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label {
                        Text("Home")
                    } icon: {
                        Image(systemName: selectedTab == .dashboard ? "house.fill" : "house")
                    }
                }
                .tag(Tab.dashboard)

            // Trends Tab
            TrendsView()
                .tabItem {
                    Label {
                        Text("Trends")
                    } icon: {
                        Image(systemName: selectedTab == .trends ? "chart.bar.fill" : "chart.bar")
                    }
                }
                .tag(Tab.trends)

            // Paths Tab
            PathsView()
                .tabItem {
                    Label {
                        Text("Paths")
                    } icon: {
                        Image(systemName: selectedTab == .paths ? "map.fill" : "map")
                    }
                }
                .tag(Tab.paths)
        }
        .accentColor(.accent)
    }
}

#Preview {
    MainTabView()
}
