//
//  LocationPickerDelegate.swift
//  Nyangjoop
//
//  Created by Lee on 9/27/25.
//

import Foundation
import CoreLocation

protocol LocationPickerDelegate: AnyObject {
    func didSelectLocation(coordinate: CLLocationCoordinate2D, address: String)
}
