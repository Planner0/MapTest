//
//  NewViewController.swift
//  MapTest
//
//  Created by ALEKSANDR POZDNIKIN on 05.12.2022.
//

import UIKit
import MapKit
import CoreLocation

class MapScreen: UIViewController {
    private var mapPoint = MKMapPoint()
    private var locationManager: CLLocationManager?
    private var mapView = MKMapView()
    private var startLocation: CLLocation?
    private var geocoder: CLGeocoder?
    
    private var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .systemBlue
        label.text = "Distance"
        label.backgroundColor = .white
        label.frame.size = .init(width: 10, height: 16)
        return label
    }()
    private var distance: MKDistanceFormatter = {
        let dist = MKDistanceFormatter()
        dist.units = .metric
        dist.unitStyle = .abbreviated
        return dist
    }()
    private let address: UITextField = {
        let textField = UITextField()
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.textColor = .black
        textField.backgroundColor = .systemGray6
        textField.font = .systemFont(ofSize: 15, weight: .regular)
        textField.tintColor = UIColor(named: "AccentColor")
        textField.autocapitalizationType = .none
        textField.placeholder = "Example: apple park, Cupertino, CA"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    private let goButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.frame.size = .init(width: 16, height: 16)
        button.setTitle("GO", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(goTo), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        
    }
    private func solveDestination(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        let pointStart = MKMapPoint(startPoint)
        let pointEnd = MKMapPoint(endPoint)
        let solveDistance = pointStart.distance(to: pointEnd)
        let pathLength = distance.string(fromDistance: solveDistance)
        self.label.text = pathLength
        print(pathLength)
    }
    
    @objc func goTo() {
            print("touch")
        self.lookUpGeocoding(address: self.address.text!)
    }
    private func routeSwitch(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        // Create MKPlaceMark for start position and destination.
        let origin = MKPlacemark(coordinate: startPoint, addressDictionary: nil)
        let destination = MKPlacemark(coordinate: endPoint, addressDictionary: nil)
        
        // Create MKDirections request with locations defined above.
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: origin)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        // Make direction request.
        let direction = MKDirections(request: request)
        direction.calculate { [weak self] (response, error) in
            guard let response = response else {
                print(error!)
                return }
            //Add route polyline
            for route in response.routes {
                self?.mapView.addOverlay(route.polyline, level: .aboveLabels)
            }
        }
    }
    private func lookUpGeocoding(address: String) {
        self.mapView.removeOverlays(mapView.overlays)
        self.mapView.removeAnnotations(mapView.annotations)
            geocoder = CLGeocoder()
            geocoder?.geocodeAddressString(address) { [weak self] placemark, error in
                guard let strongSelf = self else { return }
                guard let placeMark = placemark?.first else {
                    print(error)
                    let alert = customAlert(message: "Address incorrect")
                    self?.present(alert, animated: true, completion: nil)
                    return }
                let latitude = placeMark.location?.coordinate.latitude
                let longitude = placeMark.location?.coordinate.longitude
                let coordinates = "\(latitude) \(longitude)"
                print(coordinates)
                let location = CLLocation.init(latitude: latitude!,longitude: longitude!)
                strongSelf.addAnnotationAtStartAndEnd(point: location.coordinate)
                guard let coordinate = strongSelf.locationManager?.location else { return }
                strongSelf.routeSwitch(startPoint: coordinate.coordinate, endPoint: location.coordinate)
                strongSelf.solveDestination(startPoint: coordinate.coordinate, endPoint: location.coordinate)
            }
    }
    private func addAnnotationAtStartAndEnd(point: CLLocationCoordinate2D) {
        // Create annotation for start location and destination.
        var annotations = [MKAnnotation]()
        
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = point
        startAnnotation.title = self.address.text
        annotations.append(startAnnotation)
        mapView.addAnnotations(annotations)
    }
    private func setup() {
        self.mapView.delegate = self
        self.mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .realistic)
        self.view.addSubview(mapView)
        self.mapView.addSubview(address)
        self.mapView.addSubview(goButton)
        self.mapView.addSubview(label)
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        checkIfLocationServicesIsEnabled()
        NSLayoutConstraint.activate([
            self.mapView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.address.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 70),
            self.address.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.address.widthAnchor.constraint(equalToConstant: 250),
            
            self.goButton.centerYAnchor.constraint(equalTo: self.address.centerYAnchor),
            self.goButton.leadingAnchor.constraint(equalTo: self.address.trailingAnchor, constant: 20),
            
            self.label.bottomAnchor.constraint(equalTo: self.address.bottomAnchor, constant: 20),
            self.label.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20)
        ])
    }
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    private func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()

        } else {
            print("show alert letting the user know they have to turn this on.")
        }
    }
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
            
        case .notDetermined:
            print(".notDetermined")
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("Your location is restricted  likely due to parental controls.")
        case .denied:
            print("You have denied this app location permission. Go into settings to cgange it.")
        case .authorizedWhenInUse, .authorizedAlways:
            print(".authorizedWhenInUse .authorizedAlways")
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = true
            //locationManager.requestLocation()
            mapView.showsUserLocation = true
            guard let coordinate = locationManager.location else { return }
            mapView.centerToLocation(coordinate)
            self.mapPoint = MKMapPoint(coordinate.coordinate)
        @unknown default:
            break
        }
    }
}
extension MapScreen: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if startLocation == nil {
            startLocation = locations.first
            print(startLocation)
        } else {
            guard let latest = locations.first else { return }
            let distanceMeters = startLocation?.distance(from: latest)
            //print("distance in meters: \(distanceMeters!)")
        }
        //print(#function)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
        print(#function)
    }
}
extension MapScreen: MKMapViewDelegate {
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        print(#function)
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.systemBlue
        renderer.lineWidth = 5.0
        return renderer
    }
 }
func customAlert(message: String) -> UIAlertController {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    let actionOk = UIAlertAction(title: "OK", style: .cancel) { actionOk in
        print("Tap Ok")
    }
    alert.addAction(actionOk)
    return alert
}
