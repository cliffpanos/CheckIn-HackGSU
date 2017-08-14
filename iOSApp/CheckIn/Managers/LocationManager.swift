//
//  LocationManager.swift
//  True Pass
//
//  Created by Cliff Panos on 8/13/17.
//  Copyright © 2017 Clifford Panos. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManager {
    
    static var sharedLocationManager = CLLocationManager()
    
    static var userLocation: CLLocation? {
        return sharedLocationManager.location
    }
    
    static var nearestLocation: TPLocation? {
        if C.truePassLocations.isEmpty { return nil }
        
        return C.nearestTruePassLocations[0]
    }
    
    
    
    
}



//MARK: - Utility functions
extension LocationManager {
    
    static func address(for location: CLLocation, completion: @escaping (_ address: [String: Any]?, _ error: Error?) -> ()) {
        
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            
            if let error = error {
                completion(nil, error)
            } else {
                
                let placeMark = placemarks?[0]
                
                guard let address = placeMark?.addressDictionary  as? [String: Any] else {
                    return
                }
                
                completion(address, nil)
                
            }
            
        }
    }
}