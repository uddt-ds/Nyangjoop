//
//  LocationManager.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import UIKit
import CoreLocation
import RxSwift
import RxCocoa


final class LocationManager: NSObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()

    private let currentLocationRelay = BehaviorRelay<CLLocation?>(value: nil)
    private let authorizationStatusRelay = BehaviorRelay<CLAuthorizationStatus>(value: .notDetermined)
    private let locationErrorRelay = PublishRelay<LocationError>()

    var currentLocation: Observable<CLLocation?> {
        currentLocationRelay.asObservable()
    }

    var authorizationStatus: Observable<CLAuthorizationStatus> {
        authorizationStatusRelay.asObservable()
    }

    var locationError: Observable<LocationError> {
        locationErrorRelay.asObservable()
    }

    var isLocationEnabled: Bool {
        return authorizationStatusRelay.value == .authorizedWhenInUse ||
        authorizationStatusRelay.value == .authorizedAlways
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10

        authorizationStatusRelay.accept(locationManager.authorizationStatus)
    }

    func requestLocationPermission() {
        guard locationManager.authorizationStatus == .notDetermined else {
            if !isLocationEnabled {
                locationErrorRelay.accept(.permissionDenied)
            }

            return
        }

        locationManager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() -> Single<CLLocation> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(LocationError.unknown))
                return Disposables.create()
            }

            guard self.isLocationEnabled else {
                observer(.failure(LocationError.permissionDenied))
                return Disposables.create()
            }

            if let currentLocation = self.currentLocationRelay.value,
               abs(currentLocation.timestamp.timeIntervalSinceNow) < 30 {
                observer(.success(currentLocation))
                return Disposables.create()
            }

            let disposable = self.currentLocation
                .compactMap { $0 }
                .take(1)
                .timeout(.seconds(10), scheduler: MainScheduler.instance)
                .subscribe(
                    onNext: { location in
                        observer(.success(location))
                    },
                    onError: { error in
                        observer(.failure(LocationError.timeout))
                    })

            self.locationManager.requestLocation()

            return disposable
        }
    }

    func openLocationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    func startUpdatingLocation() {
        guard isLocationEnabled else {
            locationErrorRelay.accept(.permissionDenied)
            return
        }

        guard CLLocationManager.locationServicesEnabled() else {
            locationErrorRelay.accept(.locationServiceDisabled)
            return
        }

        locationManager.startUpdatingLocation()
    }
}


enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationServiceDisabled
    case locationUnavailable
    case networkError
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
             return "위치 권한이 거부되었습니다. 설정에서 위치 권한을 허용해주세요."
         case .locationServiceDisabled:
             return "위치 서비스가 비활성화되어 있습니다."
         case .locationUnavailable:
             return "현재 위치를 찾을 수 없습니다."
         case .networkError:
             return "네트워크 오류로 위치를 찾을 수 없습니다."
         case .timeout:
             return "위치 검색 시간이 초과되었습니다."
         case .unknown:
             return "알 수 없는 오류가 발생했습니다."
         }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocationRelay.accept(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print("Location error: \(error)")

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationErrorRelay.accept(.permissionDenied)
            case .network:
                locationErrorRelay.accept(.networkError)
            case .locationUnknown:
                locationErrorRelay.accept(.locationUnavailable)
            default:
                locationErrorRelay.accept(.unknown)
            }
        } else {
            locationErrorRelay.accept(.unknown)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusRelay.accept(manager.authorizationStatus)

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            locationErrorRelay.accept(.permissionDenied)
        case .notDetermined:
            break
        default:
            break
        }
    }
}
