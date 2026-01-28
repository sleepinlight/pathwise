//
//  PathsView.swift
//  pathwise
//
//  Loop walking route generator
//

import SwiftUI
import MapKit

struct PathsView: View {
    @StateObject private var viewModel = PathsViewModel()
    @StateObject private var devSettings = DeveloperSettings.shared

    // Observe manual route VM separately to catch its state changes
    @ObservedObject private var manualRouteVM: ManualRouteViewModel

    init() {
        let vm = PathsViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        _manualRouteVM = ObservedObject(wrappedValue: vm.manualRouteVM)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Map View - Use interactive version when drawing or showing manual route
                if manualRouteVM.isDrawing || manualRouteVM.currentRoute != nil {
                    InteractivePathMapView(
                        region: $viewModel.mapRegion,
                        routeCoordinates: manualRouteVM.currentRoute?.coordinates ?? [],
                        drawnCoordinates: manualRouteVM.drawnCoordinates,
                        startCoordinate: viewModel.locationManager.currentLocation,
                        isDrawingMode: manualRouteVM.isDrawing,
                        onDrawCoordinate: { coordinate in
                            manualRouteVM.addDrawnCoordinate(coordinate)
                        },
                        onFinishDrawing: {
                            manualRouteVM.snapToRoads()
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    PathwiseMapView(
                        region: $viewModel.mapRegion,
                        routeCoordinates: viewModel.generatedRoute?.coordinates ?? [],
                        startCoordinate: routeAnnotations.first?.coordinate
                    )
                    .ignoresSafeArea()
                }

                // Controls Overlay
                VStack {
                    Spacer()

                    VStack(spacing: Spacing.md) {
                        // Distance Picker (only shown if auto-generation is enabled)
                        if devSettings.enableAutoRouteGeneration && viewModel.generatedRoute == nil {
                            VStack(spacing: Spacing.sm) {
                                Text("Choose Distance")
                                    .font(.pathwiseCaption)
                                    .foregroundColor(.primaryText.opacity(0.6))

                                HStack(spacing: Spacing.xs) {
                                    ForEach(RouteDistance.allCases) { distance in
                                        DistancePill(
                                            distance: distance,
                                            isSelected: viewModel.selectedDistance == distance,
                                            action: {
                                                viewModel.selectedDistance = distance
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)
                            .padding(.bottom, Spacing.sm)
                            .background(Color.cardBackground)
                            .cornerRadius(CornerRadius.lg)
                            .pathwiseCardShadow()
                        }

                        // Route Info Card (when route is generated)
                        if let route = viewModel.generatedRoute {
                            RouteInfoCard(route: route, onClear: {
                                viewModel.clearRoute()
                            })
                        }

                        // Generate Button / Loading State (only shown if auto-generation is enabled)
                        if devSettings.enableAutoRouteGeneration {
                            if viewModel.isGenerating {
                                LoadingView()
                            } else if viewModel.generatedRoute == nil {
                                Button(action: {
                                    viewModel.generateRoute()
                                }) {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "sparkles")
                                            .font(.body)
                                        Text("Find a Path")
                                            .font(.pathwiseBody)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .background(
                                        viewModel.locationManager.currentLocation != nil
                                            ? Color.accent
                                            : Color.primaryText.opacity(0.3)
                                    )
                                    .cornerRadius(CornerRadius.lg)
                                }
                                .disabled(viewModel.locationManager.currentLocation == nil)
                                .pathwiseCardShadow()
                            }
                        }

                        // Manual Route Drawing (when auto-generation is disabled)
                        if !devSettings.enableAutoRouteGeneration {
                            if let route = manualRouteVM.currentRoute {
                                // Show completed route
                                ManualRouteInfoCard(route: route, onClear: {
                                    manualRouteVM.clearRoute()
                                })
                            } else if manualRouteVM.isDrawing {
                                // Drawing mode UI
                                ManualRouteDrawingCard(
                                    isProcessing: manualRouteVM.isProcessing,
                                    hasDrawnPath: !manualRouteVM.drawnCoordinates.isEmpty,
                                    onCancel: {
                                        manualRouteVM.clearRoute()
                                    }
                                )
                            } else {
                                // Start drawing button
                                Button(action: {
                                    manualRouteVM.startDrawing()
                                }) {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "scribble")
                                            .font(.body)
                                        Text("Draw Route")
                                            .font(.pathwiseBody)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .background(Color.accent)
                                    .cornerRadius(CornerRadius.lg)
                                }
                                .pathwiseCardShadow()
                            }
                        }

                        // Error Message
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error, onDismiss: {
                                viewModel.errorMessage = nil
                            })
                        }

                        // Location Permission Message
                        if viewModel.locationManager.currentLocation == nil &&
                           viewModel.locationManager.authorizationStatus != .notDetermined {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "location.slash.fill")
                                    .foregroundColor(.secondaryAccent)
                                    .font(.caption)

                                Text("Enable location services to generate paths")
                                    .font(.pathwiseCaption)
                                    .foregroundColor(.primaryText.opacity(0.8))
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondaryAccent.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.onAppear()
            }
            .onChange(of: viewModel.locationManager.hasLocation) { hasLocation in
                // Update map region when location becomes available
                if hasLocation && viewModel.generatedRoute == nil {
                    viewModel.updateMapRegion()
                }
            }
        }
    }

    private var routeAnnotations: [RouteAnnotation] {
        guard let route = viewModel.generatedRoute,
              let startCoordinate = route.coordinates.first else {
            // Show user location if available
            if let userLocation = viewModel.locationManager.currentLocation {
                return [RouteAnnotation(coordinate: userLocation, isStart: true)]
            }
            return []
        }

        return [RouteAnnotation(coordinate: startCoordinate, isStart: true)]
    }
}

// MARK: - Map View with Route

struct MapViewWithRoute: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let routeCoordinates: [CLLocationCoordinate2D]
    let startCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }

        // Remove old overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        // Add route polyline if available
        if !routeCoordinates.isEmpty {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
        }

        // Add start marker if available
        if let start = startCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = start
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithRoute

        init(_ parent: MapViewWithRoute) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemOrange
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "StartMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false

                // Create custom marker view
                let markerView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                markerView.backgroundColor = UIColor.systemOrange
                markerView.layer.cornerRadius = 10
                markerView.layer.borderWidth = 3
                markerView.layer.borderColor = UIColor.white.cgColor
                annotationView?.addSubview(markerView)
                annotationView?.frame = markerView.frame
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
    }
}

// MARK: - Route Annotation

struct RouteAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let isStart: Bool
}

// MARK: - Distance Pill

struct DistancePill: View {
    let distance: RouteDistance
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(distance.displayText)
                .font(.pathwiseBody)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primaryText)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.accent : Color.primaryBackground)
                .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Route Info Card

struct RouteInfoCard: View {
    let route: WalkingRoute
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Path")
                        .font(.pathwiseSubheadline)
                        .foregroundColor(.primaryText)

                    HStack(spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "figure.walk")
                                .font(.caption)
                                .foregroundColor(.accent)
                            Text(route.distanceFormatted)
                                .font(.pathwiseBody)
                                .foregroundColor(.primaryText)
                        }

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.accent)
                            Text(route.durationFormatted)
                                .font(.pathwiseBody)
                                .foregroundColor(.primaryText)
                        }
                    }
                }

                Spacer()

                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.primaryText.opacity(0.5))
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            ProgressView()
                .tint(.accent)

            Text("Searching for a cozy path...")
                .font(.pathwiseBody)
                .foregroundColor(.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

// MARK: - Manual Route Drawing Card

struct ManualRouteDrawingCard: View {
    let isProcessing: Bool
    let hasDrawnPath: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if isProcessing {
                        Text("Snapping to Roads...")
                            .font(.pathwiseSubheadline)
                            .foregroundColor(.primaryText)
                    } else {
                        Text("Drawing Route")
                            .font(.pathwiseSubheadline)
                            .foregroundColor(.primaryText)

                        Text(hasDrawnPath ? "Lift finger to snap to roads" : "Draw your path with your finger")
                            .font(.pathwiseCaption)
                            .foregroundColor(.primaryText.opacity(0.6))
                    }
                }

                Spacer()

                if isProcessing {
                    ProgressView()
                        .tint(.accent)
                }
            }

            // Cancel button
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "xmark")
                            .font(.caption)
                        Text("Cancel")
                            .font(.pathwiseCaption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primaryText.opacity(0.7))
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.primaryBackground)
                    .cornerRadius(CornerRadius.md)
                }

                Spacer()
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

// MARK: - Manual Route Info Card

struct ManualRouteInfoCard: View {
    let route: ManualRoute
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Route")
                        .font(.pathwiseSubheadline)
                        .foregroundColor(.primaryText)

                    Text("Drawn and snapped to roads")
                        .font(.pathwiseCaption)
                        .foregroundColor(.primaryText.opacity(0.6))
                }

                Spacer()

                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.primaryText.opacity(0.5))
                }
            }

            // Stats
            HStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.accent)
                    Text(route.distanceFormatted)
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText)
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.accent)
                    Text(route.durationFormatted)
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText)
                }

                Spacer()
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.secondaryAccent)
                .font(.caption)

            Text(message)
                .font(.pathwiseCaption)
                .foregroundColor(.primaryText.opacity(0.8))
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.primaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryAccent.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    PathsView()
}
