import WeatherKit
import Foundation

// This will help us see what properties WeatherAlert actually has
func checkWeatherAlertProperties() {
    // Create a dummy reference to trigger autocomplete information
    let alert: WeatherKit.WeatherAlert? = nil
    if let alert = alert {
        // Try to access common date properties
        let _ = alert.metadata
        // The compilation will tell us what properties actually exist
    }
}
