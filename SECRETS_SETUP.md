# API Keys and Secrets Setup

This project uses a gitignored secrets file to protect API keys from being committed to version control.

## Setup for Development

1. **Copy the example secrets file:**
   ```bash
   cp pathwise/Config/Secrets.swift.example pathwise/Config/Secrets.swift
   ```

2. **Add your API keys to `Secrets.swift`:**
   - **Stadia Maps API Key**: Get one at https://client.stadiamaps.com/signup/
   - **Mapbox Access Token**: Get one at https://account.mapbox.com/access-tokens/
   - Replace the placeholder values with your actual keys

3. **Build and run the project**

## Important Notes

- `Secrets.swift` is gitignored and will never be committed
- `Secrets.swift.example` is a template - do not add real keys to this file
- All developers must create their own `Secrets.swift` file locally
- Never commit API keys to version control

## Current API Keys

| Service | Key Location | Purpose |
|---------|-------------|---------|
| Stadia Maps | `Secrets.stadiaMapsAPIKey` | Map tiles, routing, and geocoding |
| Mapbox | `Secrets.mapboxAccessToken` | Alternative routing and directions |

## Adding New Secrets

When adding new API keys:

1. Add the key to `pathwise/Config/Secrets.swift`:
   ```swift
   static let newAPIKey = "your-key-here"
   ```

2. Update `Secrets.swift.example` with a placeholder:
   ```swift
   static let newAPIKey = "YOUR_NEW_API_KEY_HERE"
   ```

3. Update this README with the new key information
