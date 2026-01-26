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
