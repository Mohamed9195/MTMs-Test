//
//  ViewController.swift
//  MTMs
//
//  Created by mohamed hashem on 04/02/2021.
//

import UIKit
import Firebase
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var homeMapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var locationTitleLabel: UILabel!

    private let annotation = MKPointAnnotation()
    private var locationManger = CLLocationManager()
    private var coordinateRegion = MKCoordinateRegion()
    private let sourceAnnotation = MKPointAnnotation()
    private let destinationAnnotation = MKPointAnnotation()

    private var destinationLocation: CLLocationCoordinate2D?
    private var sourceLocation: CLLocationCoordinate2D?

    var currentLocation: CLLocationCoordinate2D?
    var getCurrentLocation = true

    override func viewDidLoad() {
        super.viewDidLoad()

        handleFirebaseData()
        setLocationManger()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // location manger
    private func setLocationManger() {
        locationManger.delegate = self
        locationManger.requestWhenInUseAuthorization()
        locationManger.desiredAccuracy = kCLLocationAccuracyBest
       // locationManger.allowsBackgroundLocationUpdates = true
        locationManger.startUpdatingLocation()
    }

    // current Location
    private func setMapKitCurrentLocation(locationCoordinate: CLLocationCoordinate2D) {
        coordinateRegion.center = locationCoordinate

        coordinateRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        homeMapView.setRegion(coordinateRegion, animated: true)

        homeMapView.showsUserLocation = true
        homeMapView.isZoomEnabled = true
        homeMapView.annotations
            .compactMap { $0 as? MKPointAnnotation }
            .forEach { existingMarker in
                existingMarker.coordinate = locationCoordinate
        }

        homeMapView.addAnnotation(annotation)

        currentLocation = locationCoordinate

        setCurrentLocationName(currentLocation: locationCoordinate)
    }

    // create map kit
    private func setMapKit(sourceLocationCoordinate: CLLocationCoordinate2D?,
                           destinationLocationCoordinate: CLLocationCoordinate2D?) {

        guard  let sourceLat = sourceLocationCoordinate?.latitude,
            let sourceLong = sourceLocationCoordinate?.longitude else {
                return
        }

        guard let destinationLat = destinationLocationCoordinate?.latitude,
            let destinationLong = destinationLocationCoordinate?.longitude else {
                return
        }

        let destinationLocation = CLLocationCoordinate2DMake(destinationLat, destinationLong)
        let sourceLocation = CLLocationCoordinate2DMake(sourceLat, sourceLong)

        let sourcePlacement = MKPlacemark(coordinate: sourceLocation)
        let destinationPlacement = MKPlacemark(coordinate: destinationLocation)

        let sourceItem = MKMapItem(placemark: sourcePlacement)
        let destinationItem = MKMapItem(placemark: destinationPlacement)

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceItem
        directionRequest.destination = destinationItem
        directionRequest.transportType = .any

        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, error) in
            guard let response = response else {
                if let error = error {
                    print("error", error)
                }
                return
            }

            let routes = response.routes[0]
            self.homeMapView.addOverlay(routes.polyline, level: .aboveRoads)

            let rect = routes.polyline.boundingMapRect
            self.homeMapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }

        sourceAnnotation.coordinate = sourceLocation
        destinationAnnotation.coordinate = destinationLocation

        homeMapView.showsScale = true
        homeMapView.showsPointsOfInterest = true
        homeMapView.showsUserLocation = true
        homeMapView.isZoomEnabled = true

        homeMapView.addAnnotation(sourceAnnotation)
        homeMapView.addAnnotation(destinationAnnotation)

        currentLocation = sourceLocationCoordinate
    }

    private func setCurrentLocationName(currentLocation: CLLocationCoordinate2D) {
        // Add below code to get address for touch coordinates.
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinateRegion.center.latitude,
                                  longitude: coordinateRegion.center.longitude)
        geoCoder.reverseGeocodeLocation(location,
                                        completionHandler: { (placeMarks, error) -> Void in
                                            guard let placeMark = placeMarks?.first else { return }
                                            var streetName = ""
                                            if let street = placeMark.thoroughfare {
                                                streetName += street + " /"
                                            }
                                            if let country = placeMark.country {
                                                streetName += country + " /"
                                            }
                                            if let zip = placeMark.isoCountryCode {
                                                streetName += zip
                                            }

                                            if streetName.isEmpty {
                                                self.locationTitleLabel.text = ""
                                            } else {
                                                self.locationTitleLabel.text = streetName
                                            }
        })
    }

    @IBAction func presseToOpenLiftSideMenue(_ sender: UIButton) {
    }
    
}

//MARK:- location Delegate
extension ViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    setLocationManger()
                }
            }
        } else {

        }
    }

    fileprivate func setDistanceWithSpeed(_ locations: [CLLocation]) {
        if let longitude = destinationLocation?.longitude, let latitude = destinationLocation?.latitude {
            let distance = locations.last?.distance(from: CLLocation(latitude: latitude, longitude: longitude)).binade
            let speed = " | " + (locations.last?.speed.description ?? "--") + " " + "M/S"
            distanceLabel.text = String(format: "%.1f", distance ?? 0.0) + " " + "Meters" + speed
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationCoordinate = locations.last?.coordinate else {
            return
        }
        sourceLocation = locationCoordinate

        if UIApplication.shared.applicationState == .active {
            if sourceLocation != nil {
                setMapKitCurrentLocation(locationCoordinate: sourceLocation!)
            }

            setMapKit(sourceLocationCoordinate: sourceLocation, destinationLocationCoordinate: destinationLocation)
            setDistanceWithSpeed(locations)
        } else {
            if sourceLocation != nil {
                setMapKitCurrentLocation(locationCoordinate: sourceLocation!)
            }
            setMapKit(sourceLocationCoordinate: sourceLocation, destinationLocationCoordinate: destinationLocation)
            setDistanceWithSpeed(locations)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = .red
        render.lineWidth = 2

        return render
    }
}

//MARK:- annotation Delegate
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView")

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
        }

        annotationView?.image = UIImage(named: "pin")
        annotationView?.canShowCallout = true
        return annotationView
    }
}

extension ViewController {
    private func handleFirebaseData() {
        let db = Firestore.firestore()
        db.collection("sourceLocation").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let serviceResult = document.data()
                    self.destinationLocation = CLLocationCoordinate2D(latitude: serviceResult["destinationLatitude"] as? Double ?? 0.0,
                                                                       longitude: serviceResult["destinationLongitude"] as? Double ?? 0.0)
                    self.sourceLocation = CLLocationCoordinate2D(latitude: serviceResult["sourceLatitude"] as? Double ?? 0.0,
                                                                       longitude: serviceResult["sourceLongitude"] as? Double ?? 0.0)
                    self.setMapKit(sourceLocationCoordinate: self.sourceLocation,
                                   destinationLocationCoordinate:  self.destinationLocation)
                }
            }
        }
    }
}
