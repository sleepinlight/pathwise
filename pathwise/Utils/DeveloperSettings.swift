//
//  DeveloperSettings.swift
//  pathwise
//
//  Developer-only settings for testing different scenarios
//  IMPORTANT: This should never be exposed to production users
//

import Foundation
import Combine

enum MockScenario: String, CaseIterable, Identifiable {
    case normal = "Normal (Multiple Windows)"
    case inGoldenWindow = "In Golden Window Now"
    case continuousWindow = "Continuous Time Range"
    case fallbackCold = "Fallback: Cold Weather"
    case fallbackRainy = "Fallback: Rainy"
    case splitWalk = "Split Walk Suggestion"
    case noFreeTime = "No Windows: Fully Booked"
    case extremeWeather = "No Windows: Extreme Weather"
    case scheduleTooTight = "No Windows: Schedule Too Tight"

    var id: String { rawValue }
}

class DeveloperSettings: ObservableObject {
    static let shared = DeveloperSettings()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "devMenuEnabled")
        }
    }

    @Published var currentScenario: MockScenario {
        didSet {
            UserDefaults.standard.set(currentScenario.rawValue, forKey: "devMockScenario")
        }
    }
    
    @Published var enableMocks: Bool {
        didSet {
            UserDefaults.standard.set(enableMocks, forKey: "devEnableMocks")
            NotificationCenter.default.post(name: .devMocksToggled, object: nil)
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "devMenuEnabled")

        if let scenarioRaw = UserDefaults.standard.string(forKey: "devMockScenario"),
           let scenario = MockScenario(rawValue: scenarioRaw) {
            self.currentScenario = scenario
        } else {
            self.currentScenario = .normal
        }
        
        self.enableMocks = UserDefaults.standard.bool(forKey: "devEnableMocks")
    }

    // Secret gesture to enable dev menu: triple tap on version number
    func toggleDevMenu() {
        isEnabled.toggle()
    }
}
extension Notification.Name {
    static let devMocksToggled = Notification.Name("devMocksToggled")
}

