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
    private let currentLocationRelay = BehaviorRelay<CLLocation?>(value: nil)
    private let authorizationStatusRelay = BehaviorRelay<CLAuthorizationStatus>(value: .notDetermined)

    private var isUpdatingLocation = false

    private override init() {
        super.init()
        setupLocationManager()

    }

    var currentLocation: Observable<CLLocation?> {
        currentLocationRelay.asObservable()
    }

    var authorizationStatus: Observable<CLAuthorizationStatus> {
        authorizationStatusRelay.asObservable()
    }

    var isLocationEnabled: Bool {
        let status = authorizationStatusRelay.value
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var isPermissionNotDetermined: Bool {
        return authorizationStatusRelay.value == .notDetermined
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        authorizationStatusRelay.accept(locationManager.authorizationStatus)

        if isLocationEnabled {
            startUpdatingLocation()
        }
    }

    private func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        print("위치 업데이트 시작")
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }

    private func stopUpdatingLocation() {
        guard isUpdatingLocation else { return }
        print("위치 업데이트 중지")
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }

    func getCurrentLocation(requestPermissionIfNeeded: Bool = false) -> Single<CLLocation> {
        return Single<CLLocation>.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(LocationError.unknown))
                return Disposables.create()
            }

            let status = self.locationManager.authorizationStatus

            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                // 권한이 있어도 시스템 위치 서비스가 꺼져있을 수 있음
                // 하지만 requestLocation 실패 시 didFailWithError에서 처리됨
                self.locationManager.requestLocation()
                let disposable = self.currentLocation
                    .compactMap { $0 }
                    .take(1)
                    .subscribe(onNext: { location in
                        observer(.success(location))
                    })
                return disposable

            case .denied, .restricted:
                observer(.failure(LocationError.permissionDenied))
                return Disposables.create()

            case .notDetermined:
                guard requestPermissionIfNeeded else {
                    observer(.failure(LocationError.permissionNotDetermined))
                    return Disposables.create()
                }

                let disp = self.authorizationStatus
                    .skip(1)
                    .take(1)
                    .subscribe(onNext: { newStatus in
                        if newStatus == .authorizedAlways || newStatus == .authorizedWhenInUse {
                            self.locationManager.requestLocation()
                            _ = self.currentLocation
                                .compactMap { $0 }
                                .take(1)
                                .subscribe(onNext: { location in
                                    observer(.success(location))
                                })
                        } else {
                            observer(.failure(LocationError.permissionDenied))
                        }
                    })

                self.locationManager.requestWhenInUseAuthorization()
                return disp

            @unknown default:
                observer(.failure(LocationError.unknown))
                return Disposables.create()
            }
        }
    }

    private func waitForLocation(timeout: Int) -> Single<CLLocation> {
        return Single<CLLocation>.create { [weak self] observer -> Disposable in
            guard let self = self else {
                observer(.failure(LocationError.unknown))
                return Disposables.create()
            }

            let disposable = self.currentLocation
                .compactMap { $0 }
                .filter { [weak self] location in
                    guard let self = self else { return false }
                    return self.isRealLocation(location)
                }
                .take(1)
                .timeout(.seconds(timeout), scheduler: MainScheduler.instance)
                .subscribe(
                    onNext: { location in
                        print("위치 받음: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        observer(.success(location))
                    },
                    onError: { _ in
                        print("위치 타임아웃")
                        observer(.failure(LocationError.timeout))
                    }
                )

            return disposable
        }
    }

    private func isRealLocation(_ location: CLLocation) -> Bool {
        let defaultLat = AppLocationConfig.defaultCoordinate.latitude
        let defaultLon = AppLocationConfig.defaultCoordinate.longitude

        return !(abs(location.coordinate.latitude - defaultLat) < 0.0001 &&
                 abs(location.coordinate.longitude - defaultLon) < 0.0001)
    }

    func openLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    func getAddressFromLocation(_ location: CLLocation) -> Single<String> {
        return Single<String>.create { observer in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    observer(.failure(error))
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    observer(.failure(LocationError.locationUnavailable))
                    return
                }
                
                var addressComponents: [String] = []
                
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                if let subLocality = placemark.subLocality {
                    addressComponents.append(subLocality)
                }
                
                let address = addressComponents.joined(separator: " ")
                observer(.success(address))
            }
            return Disposables.create()
        }
    }
}

enum LocationError: Error, LocalizedError, Equatable {
    case permissionDenied
    case permissionNotDetermined
    case locationUnavailable
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "위치 권한이 거부되었습니다. 설정에서 위치 권한을 허용해주세요."
        case .permissionNotDetermined:
            return "위치 권한이 필요합니다. 지도 화면에서 현위치 버튼을 먼저 눌러주세요."
        case .locationUnavailable:
            return "현재 위치를 찾을 수 없습니다."
        case .timeout:
            return "위치를 찾는 중입니다. 잠시만 기다려주세요."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print(" 위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocationRelay.accept(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("위치 서비스 거부됨")
                stopUpdatingLocation()
            case .locationUnknown:
                print("위치를 찾을 수 없음 (GPS 신호 약함)")
            default:
                print("기타 위치 오류: \(clError.code)")
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        print("권한 상태 변경: \(newStatus.rawValue)")
        authorizationStatusRelay.accept(newStatus)

        if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            startUpdatingLocation()
        } else if newStatus == .denied || newStatus == .restricted {
            stopUpdatingLocation()
        }
    }
}
