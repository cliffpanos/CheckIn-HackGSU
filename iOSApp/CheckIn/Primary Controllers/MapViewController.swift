//
//  MapViewController.swift
//  True Pass
//
//  Created by Cliff Panos on 4/2/17.
//  Copyright © 2017 Clifford Panos. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase

class MapViewController: ManagedViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    let locationManager = LocationManager.sharedLocationManager

    @IBOutlet weak var outerMapButtonsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        mapView.mapType = .standard
//        outerMapButtonsView.shadowed()
        
        for location in C.truePassLocations {
            mapView.addAnnotation(location)
            let circle = MKCircle(center: location.coordinate, radius: 0.01 as CLLocationDistance)
            self.mapView.add(circle)
        }
        
        if let userLocation = LocationManager.userLocation {
            zoom(to: userLocation.coordinate, withViewSize: 0.03)
        } else {
            zoomToCheckInLocation()
        }
        let _ = LocationManager.coreDataLocations
        reloadAllLocations()
        
        let userListService = FirebaseService(entity: .TPUserList)
        userListService.reference.child(Accounts.userIdentifier).observe(DataEventType.childAdded, with: { dataSnapshot in
            let locationIdentifier = dataSnapshot.key
            let locationService = FirebaseService(entity: .TPLocation)
            locationService.retrieveData(forIdentifier: locationIdentifier) { object in
                let location = object as! TPLocation
                var contains = false
                for current in C.truePassLocations { if current == location { contains = true } }
                if !contains {
                    print("Adding location to collection view")
                    C.truePassLocations.append(location)
                    self.mapView.addAnnotation(location)
                    self.collectionView.reloadData()
                }
            }
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func reloadAllLocations() {
        let userListService = FirebaseService(entity: .TPUserList)
        let locationService = FirebaseService(entity: .TPLocation)
        userListService.retrieveList(forIdentifier: Accounts.userIdentifier) { pairs in
            
            let numberOfLocations = pairs.count
            var validRefreshedLocationIdentifiers = [String]()
            
            var currentIndex = 0
            for (locationIdentifier, _) in pairs {
                locationService.retrieveData(forIdentifier: locationIdentifier) { object in
                    let location = object as! TPLocation
                    var contains = false
                    for current in C.truePassLocations { if current == location { contains = true } }
                    if !contains {
                        validRefreshedLocationIdentifiers.append(location.identifier!)
                        print("Adding location to collection view")
                        C.truePassLocations.append(location)
                        self.mapView.addAnnotation(location)
                        self.collectionView.reloadData()
                    }
                    
                    //TODO: handle updating of CoreDataLocations
                    
                    if currentIndex == numberOfLocations - 1 {
                        //Then we have done the work for the last possible location
                        let allLocationsUpdatedNotification = Notification(name: Notification.Name.init("AllLocationsUpdated"))
                        NotificationCenter.default.post(allLocationsUpdatedNotification)
                    }
                    currentIndex += 1

                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    
    @IBOutlet weak var mapButtonsView: UIView!
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapButtonsView.layer.cornerRadius = mapButtonsView.bounds.width / 3.8
    }
    
    @IBAction func selectMapType(_ sender: UIButton) {
        LocationManager.chooseMapType(for: mapView, from: sender, arrow: .down, in: self)
    }
    
    @IBOutlet weak var zoomToUserLocationButton: CDButton!
    @IBAction func zoomButtonPressed(_ sender: Any) {
        LocationManager.zoomToUserLocation(in: mapView)
    }
    
    func zoomToCheckInLocation() {
        if let nearest = C.nearestTruePassLocations.first {
            zoom(to: nearest.coordinate, withViewSize: 0.02)
        }
    }
    
    func zoomToUserLocation() {
        LocationManager.zoomToUserLocation(in: mapView)
    }
    
    func zoom(to location: CLLocationCoordinate2D, withViewSize sizeDelta: CLLocationDegrees) {
        let newRegion = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: sizeDelta, longitudeDelta: sizeDelta))
        mapView.setRegion(newRegion, animated: true)
        let camera = MKMapCamera(lookingAtCenter: location, fromEyeCoordinate: CLLocationCoordinate2D(latitude: location.latitude - 0.001, longitude: location.longitude - 0.001), eyeAltitude: 1)
        mapView.setCamera(camera, animated: true)
    }

    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = ((status == .authorizedAlways) || status == .authorizedWhenInUse)
        //zoomToUserLocation()
    }
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
        print("Located user")
    }
    
    func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
        print("started locating user")
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("LOCATION UPDATED")
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = UIColor.white
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        zoomToUserLocationButton.tintColor = mapView.isUserLocationVisible ? UIColor.TrueColors.lightBlue : UIColor.TrueColors.trueBlue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLocationDetailEmbedder", let cell = sender as? LocationCell {
            let detailVC = segue.destination as! LocationDetailEmbedderController
            detailVC.location = cell.location
        }
    }
    
    override func deviceOrientationDidChange() {
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

}



extension MapViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return C.truePassLocations.count + 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: UICollectionViewCell
        switch (indexPath.row) {
        case 0 :
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "truePassCell", for: indexPath) as! LocationCell
        case 1..<C.nearestTruePassLocations.count + 1 :
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "locationCell", for: indexPath)
            (cell as! LocationCell).decorate(for: C.nearestTruePassLocations[indexPath.row - 1], in: self)
        default :
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addLocationCell", for: indexPath)
        }
        
        cell.layer.masksToBounds = false
        let roundedView = cell.subviews.first!
        roundedView.layer.masksToBounds = false
        roundedView.layer.cornerRadius = 7
        roundedView.layer.shadowColor = UIColor.lightGray.cgColor
        roundedView.layer.shadowOffset = CGSize(width: 0, height: 0);
        roundedView.layer.shadowRadius = 8
        roundedView.layer.shadowOpacity = 0.8
        //roundedView.layer.shadowPath = UIBezierPath(rect: roundedView.layer.bounds).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? CGFloat(24) : CGFloat(16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let totalItems = collectionView.numberOfItems(inSection: 0)
        
        let verticalInset = CGFloat(16.0)
        let multiplier = UIDevice.current.userInterfaceIdiom == .pad ? CGFloat(4) : CGFloat(2)
        let cellHeight = collectionView.frame.size.height - (multiplier * verticalInset)
        var cellWidth = cellHeight - 32.5
        
        //At the beginning and end of the collectionView, we need extra 16px padding
        if indexPath.row == 0 || indexPath.row == totalItems - 1 {
            cellWidth += 16;
        }
        
        return CGSize(width: cellWidth, height: cellHeight)
        
    }

}


@IBDesignable
class LocationCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationIcon: UIImageView!
    @IBOutlet weak var locationTypeLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    var tapRecognizer: UITapGestureRecognizer!
    weak var mapViewController: MapViewController?
    
    var location: TPLocation!
    func decorate(for location: TPLocation, in mvc: MapViewController) {
        
        self.location = location
        self.mapViewController = mvc
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToLocationOnMap))
        visualEffectView.addGestureRecognizer(tapRecognizer)
        
        visualEffectView.layer.cornerRadius = visualEffectView.bounds.height / 4.0
        
        locationTypeLabel.text = (location.locationType ?? "Location").localizedUppercase
        titleLabel.text = location.shortTitle
        
        let typeDetails = TPLocationType.Details[location.type]!
        locationIcon.image = UIImage(named: typeDetails)
        backgroundImage.image = UIImage(named: "\(typeDetails)Scene")
        
    }
    
    @objc func goToLocationOnMap() {
        mapViewController?.zoom(to: location.coordinate, withViewSize: 0.01)
    }
    
}








