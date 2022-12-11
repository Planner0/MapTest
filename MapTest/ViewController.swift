//
//  ViewController.swift
//  MapTest
//
//  Created by ALEKSANDR POZDNIKIN on 04.12.2022.
//

import UIKit
import MapKit
import CoreLocation

final class ViewController: UIViewController {
    
    private var toggle: UISwitch = {
        let toggle = UISwitch()
        //toggle.title = "Add Way"
        //toggle.isOn = false
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(routeSwitch(_:)), for: .valueChanged)
        toggle.setOn(false, animated: false)
        return toggle
    }()
    private var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .systemBlue
        //label.text = "Distance"
        label.backgroundColor = .white
        //label.frame.size = .init(width: 10, height: 16)
        return label
    }()
    //private var mapPoint = MKMapPoint()
    private var distance: MKDistanceFormatter = {
        let dist = MKDistanceFormatter()
        dist.units = .metric
        dist.unitStyle = .abbreviated
        return dist
    }()
    private var locationManager = CLLocationManager()
    private var mapView = MKMapView()
    private let initialLocation = CLLocation(latitude: 37.79190, longitude: -122.44776)
    private let startPoint = CLLocationCoordinate2D(latitude: 37.79190, longitude: -122.44776)
    private let endPoint = CLLocationCoordinate2D(latitude: 37.82798, longitude: -122.48201)
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .brown
        self.setup()
    }

    private func solveDestination() {
        let pointStart = MKMapPoint(startPoint)
        let pointEnd = MKMapPoint(endPoint)
        let solveDistance = pointStart.distance(to: pointEnd)
        let pathLength = distance.string(fromDistance: solveDistance)
        self.label.text = pathLength
        print(pathLength)
    }
    @objc func switchStateDidChange(_ sender:UISwitch!)
        {
            if (sender.isOn == true){
                print("UISwitch state is now ON")
            }
            else{
                print("UISwitch state is now Off")
            }
        }
    @objc func routeSwitch(_ toggle: UISwitch) {
        if toggle.isOn {
            Task {
                print("ToggleIsON")
            }
            // Create MKPlaceMark for start position and destination.
            let origin = MKPlacemark(coordinate: startPoint)
            let destination = MKPlacemark(coordinate: endPoint)
            
            // Create MKDirections request with locations defined above.
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: origin)
            request.destination = MKMapItem(placemark: destination)
            //request.transportType = .walking
            Task {
                
                // Make direction request.
                let direction = MKDirections(request: request)
                do {
                    guard let response = try? await direction.calculate() else {return}
                    // Add route polyline
                    for route in response.routes {
                        self.mapView.addOverlay(route.polyline, level: .aboveLabels)
                    }
                    // Animate map camera for a closer look at elevated route polyline
                    
                } catch {
                    
                }
            }
        }
        
    }
    private func addAnnotationAtStartAndEnd() {
        // Create annotation for start location and destination.
        var annotations = [MKAnnotation]()
        
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = startPoint
        startAnnotation.title = "Start point"
        annotations.append(startAnnotation)
        
        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = endPoint
        endAnnotation.title = "End point"
        annotations.append(endAnnotation)
        
        // Add annotations to map view.
        mapView.addAnnotations(annotations)
    }
    private func setup() {
        let oahuCenter = CLLocation(latitude: 37.79190, longitude: -122.44776)
        let region = MKCoordinateRegion(
                      center: oahuCenter.coordinate,
                      latitudinalMeters: 5000000,
                      longitudinalMeters: 5000000)
        mapView.setCameraBoundary(
                      MKMapView.CameraBoundary(coordinateRegion: region),
                      animated: true)

        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 5000000)
        self.mapView.setCameraZoomRange(zoomRange, animated: true)
        self.mapView.centerToLocation(initialLocation, regionRadius: 50000)
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.addSubview(label)
        self.mapView.addSubview(toggle)
        
        self.view.addSubview(mapView)
        constraints()
        addAnnotationAtStartAndEnd()
        solveDestination()
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("none")
            self.mapView.showsUserLocation = true
//            var configuration = self.mapView.preferredConfiguration
//            configuration.elevationStyle = .realistic
//            guard let userLocationCoordinate = self.mapView.userLocation.location?.coordinate else {
//                return }
//            let location = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)
//            self.mapView.centerToLocation(location, regionRadius: 50000)
            //self.mapView.setCenter(userLocationCoordinate, animated: true)
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            fatalError()
        }
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = kCLDistanceFilterNone
//        locationManager.startUpdatingLocation()

    }
    private func constraints() {
        NSLayoutConstraint.activate([
            
            self.mapView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            self.label.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            //self.label.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -500),
            self.label.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            //self.label.heightAnchor.constraint(equalToConstant: 16)
            //self.label.widthAnchor.constraint(equalToConstant: 50),
            self.toggle.topAnchor.constraint(equalTo: self.mapView.topAnchor, constant: 50),
            self.toggle.trailingAnchor.constraint(equalTo: self.mapView.trailingAnchor),
            self.toggle.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor, constant: 50)
            //self.toggle.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
}
