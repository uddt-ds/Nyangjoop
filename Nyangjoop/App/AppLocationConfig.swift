//
//  AppLocationConfig.swift
//  Nyangjoop
//
//  Created by Lee on 9/28/25.
//

import CoreLocation
import MapKit

struct AppLocationConfig {
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5534, longitude: 126.9696)
    static let defaultRadius: CLLocationDistance = 1000

    static var defaultLocation: CLLocation {
        return CLLocation(latitude: defaultCoordinate.latitude, longitude: defaultCoordinate.longitude)
    }

    static var defaultRegion: MKCoordinateRegion {
        return MKCoordinateRegion(center: defaultCoordinate,
                                  latitudinalMeters: defaultRadius,
                                  longitudinalMeters: defaultRadius)
    }
}

extension MKMapView {
    func setToDefaultLoction(animated: Bool = false) {
        setRegion(AppLocationConfig.defaultRegion, animated: animated)
    }
}
