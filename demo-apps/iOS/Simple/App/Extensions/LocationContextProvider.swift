import Foundation
import UIKit
import MapKit
import Contacts
import ConvoUI

@available(iOS 15.0, *)
@MainActor
final class LocationContextProvider: NSObject, @preconcurrency ConvoUIContextProvider {
    var id: String { "chatkit.location" }
    var title: String { "Location" }
    var iconName: String { "location.fill" }
    var isAvailable: Bool { true }
    var priority: Int { 105 }
    var maximumAttachmentCount: Int { 1 }
    var shouldUseContainerPanel: Bool { true }

    func makeContext() async throws -> (any ConvoUIContextItem)? {
        // Fallback for compact mode or when panel UI is unavailable
        return LocationContextItem(
            latitude: 37.7749,
            longitude: -122.4194,
            placeName: "San Francisco, CA"
        )
    }

    func createCollectorView(onConfirm: @escaping ((any ConvoUIContextItem)?) -> Void) -> UIView? {
        let collectorView = LocationCollectorView()
        collectorView.onConfirm = onConfirm
        return collectorView
    }

    func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView? {
        guard let locationItem = item as? LocationContextItem else { return nil }
        let detailView = LocationDetailView(item: locationItem)
        detailView.onDismiss = onDismiss
        return detailView
    }

    func localizedDescription(for item: any ConvoUIContextItem) -> String {
        guard let locationItem = item as? LocationContextItem else {
            return item.displayName
        }
        return """
        Location: \(locationItem.placeName ?? "Unknown")
        Coordinates: \(String(format: "%.4f", locationItem.latitude)), \(String(format: "%.4f", locationItem.longitude))
        """
    }
}

// MARK: - Collector View

@available(iOS 15.0, *)
@MainActor
final class LocationCollectorView: UIView {
    var onConfirm: (((any ConvoUIContextItem)?) -> Void)?

    private let mapView = MKMapView()
    private let searchBar = UISearchBar()
    private let selectButton = UIButton(type: .system)
    private var selectedCoordinate: CLLocationCoordinate2D?
    private var selectedPlaceName: String?
    private var selectedPlacemark: CLPlacemark?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search for a location"
        searchBar.delegate = self
        addSubview(searchBar)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        addSubview(mapView)

        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        mapView.setRegion(initialRegion, animated: false)

        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.setTitle("Use This Location", for: .normal)
        selectButton.backgroundColor = .systemBlue
        selectButton.setTitleColor(.white, for: .normal)
        selectButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        selectButton.layer.cornerRadius = 12
        selectButton.addTarget(self, action: #selector(handleSelectButton), for: .touchUpInside)
        selectButton.isEnabled = false
        selectButton.alpha = 0.5
        addSubview(selectButton)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),

            mapView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.heightAnchor.constraint(equalToConstant: 300),

            selectButton.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 16),
            selectButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectButton.heightAnchor.constraint(equalToConstant: 50),
            selectButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        mapView.removeAnnotations(mapView.annotations)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Selected Location"
        mapView.addAnnotation(annotation)

        selectedCoordinate = coordinate
        selectedPlacemark = nil
        selectButton.isEnabled = false
        selectButton.alpha = 0.5

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    self.selectedPlacemark = placemark
                    self.selectedPlaceName = self.formatAddress(from: placemark)
                        ?? placemark.name
                        ?? String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    annotation.title = self.selectedPlaceName
                } else {
                    self.selectedPlaceName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                }
                self.selectButton.isEnabled = true
                self.selectButton.alpha = 1.0
            }
        }
    }

    @objc private func handleSelectButton() {
        guard let coordinate = selectedCoordinate else { return }
        let placeName = selectedPlaceName

        if placeName == nil {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            selectButton.isEnabled = false
            selectButton.alpha = 0.5
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let resolvedName = self.selectedPlaceName ?? self.formatAddress(from: placemarks?.first) ?? String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    let item = LocationContextItem(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        placeName: resolvedName
                    )
                    self.onConfirm?(item)
                    self.selectButton.isEnabled = true
                    self.selectButton.alpha = 1.0
                }
            }
            return
        }

        let item = LocationContextItem(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            placeName: placeName
        )

        onConfirm?(item)
    }

    private func formatAddress(from placemark: CLPlacemark?) -> String? {
        guard let placemark = placemark else { return nil }
        if let postal = placemark.postalAddress {
            let formatter = CNPostalAddressFormatter()
            let lines = formatter.string(from: postal)
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !lines.isEmpty {
                return lines.joined(separator: ", ")
            }
        }

        let components = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

@available(iOS 15.0, *)
extension LocationCollectorView: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let searchText = searchBar.text, !searchText.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, _ in
            guard let self = self,
                  let response = response,
                  let firstItem = response.mapItems.first else { return }

            let coordinate = firstItem.placemark.coordinate
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
            self.mapView.setRegion(region, animated: true)

            self.mapView.removeAnnotations(self.mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            let address = self.formatAddress(from: firstItem.placemark)
            annotation.title = address ?? firstItem.name
            self.mapView.addAnnotation(annotation)

            self.selectedCoordinate = coordinate
            self.selectedPlacemark = firstItem.placemark
            self.selectedPlaceName = address ?? firstItem.name ?? String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            self.selectButton.isEnabled = true
            self.selectButton.alpha = 1.0
        }
    }
}

@available(iOS 15.0, *)
extension LocationCollectorView: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "LocationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }
}

// MARK: - Detail View

@available(iOS 15.0, *)
final class LocationDetailView: UIView {
    var onDismiss: (() -> Void)?

    private let mapView = MKMapView()
    private let infoLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let item: LocationContextItem

    init(item: LocationContextItem) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        addSubview(closeButton)

        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.systemFont(ofSize: 16)
        infoLabel.text = """
        \(item.placeName ?? "Selected Location")

        Latitude: \(String(format: "%.6f", item.latitude))
        Longitude: \(String(format: "%.6f", item.longitude))
        """
        addSubview(infoLabel)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.isUserInteractionEnabled = false
        let coordinate = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: false)
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = item.placeName
        mapView.addAnnotation(annotation)
        addSubview(mapView)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            infoLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            mapView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func handleClose() {
        onDismiss?()
    }
}

// MARK: - Context Item

@available(iOS 15.0, *)
struct LocationContextItem: ConvoUIContextItem {
    let id = UUID()
    let providerId = "chatkit.location"
    let type = "location"
    var displayName: String { "Location" }

    let latitude: Double
    let longitude: Double
    let placeName: String?

    var codablePayload: Encodable? {
        LocationPayload(
            latitude: latitude,
            longitude: longitude,
            placeName: placeName,
            timestamp: Date().timeIntervalSince1970
        )
    }

    func encodeForTransport() throws -> Data {
        guard let payload = codablePayload as? LocationPayload else {
            throw EncodingError.invalidValue(
                codablePayload as Any,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "codablePayload is not a LocationPayload"
                )
            )
        }
        let encoder = JSONEncoder()
        return try encoder.encode(payload)
    }

    var encodingRepresentation: ConvoUIEncodingType { .json }

    var encodingMetadata: [String: String]? {
        [
            "provider": providerId,
            "type": "geo_location",
            "latitude": String(format: "%.6f", latitude),
            "longitude": String(format: "%.6f", longitude),
            "placeName": placeName ?? "",
            "localizedDescription": humanReadableDescription
        ]
    }

    var descriptionTemplates: [ContextDescriptionTemplate] {
        let place = placeName ?? ""
        return [
            ContextDescriptionTemplate(
                locale: "en",
                template: place.isEmpty
                    ? "Location at latitude {latitude}, longitude {longitude}."
                    : "Location at {placeName} (latitude {latitude}, longitude {longitude})."
            ),
            ContextDescriptionTemplate(
                locale: "zh-CN",
                template: place.isEmpty
                    ? "位置在纬度 {latitude}、经度 {longitude}。"
                    : "位置在 {placeName}（纬度 {latitude}、经度 {longitude}）。"
            )
        ]
    }

    func createPreviewView(onRemove: @escaping () -> Void) -> UIView? {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 220, height: 40))
        container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemBlue.cgColor

        let iconLabel = UILabel(frame: CGRect(x: 8, y: 10, width: 20, height: 20))
        iconLabel.text = "📍"
        iconLabel.font = UIFont.systemFont(ofSize: 16)
        container.addSubview(iconLabel)

        let nameLabel = UILabel(frame: CGRect(x: 32, y: 0, width: 160, height: 40))
        nameLabel.text = placeName ?? String(format: "%.4f, %.4f", latitude, longitude)
        nameLabel.font = UIFont.systemFont(ofSize: 13)
        nameLabel.textColor = .darkGray
        container.addSubview(nameLabel)

        let removeButton = UIButton(type: .system)
        removeButton.frame = CGRect(x: 195, y: 10, width: 20, height: 20)
        removeButton.setTitle("✕", for: .normal)
        removeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        removeButton.addAction(UIAction { _ in onRemove() }, for: .touchUpInside)
        container.addSubview(removeButton)

        return container
    }

    private var humanReadableDescription: String {
        if let place = placeName, !place.isEmpty {
            return String(format: "%@ (%.4f, %.4f)", place, latitude, longitude)
        }
        return String(format: "Lat %.4f, Lon %.4f", latitude, longitude)
    }
}

struct LocationPayload: Codable {
    let latitude: Double
    let longitude: Double
    let placeName: String?
    let timestamp: TimeInterval
}
