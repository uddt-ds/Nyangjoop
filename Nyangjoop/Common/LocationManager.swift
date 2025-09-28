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

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatusRelay.accept(locationManager.authorizationStatus)

        currentLocationRelay.accept(AppLocationConfig.defaultLocation)
    }

    // 권한 요청과 위치 요청을 하나로 통합
    func getCurrentLocation() -> Single<CLLocation> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(LocationError.unknown))
                return Disposables.create()
            }

            // 이미 권한이 있으면 바로 위치 요청
            if self.isLocationEnabled {
                let disposable = self.requestLocationDirectly()
                    .subscribe(
                        onSuccess: { location in
                            observer(.success(location))
                        },
                        onFailure: { error in
                            observer(.failure(error))
                        }
                    )
                return disposable
            }

            // 권한이 없으면 권한 요청 후 위치 요청
            let disposable = self.authorizationStatus
                .skip(1) // 현재 상태 건너뛰기
                .take(1) // 첫 번째 변경만 감지
                .flatMap { status -> Observable<CLLocation> in
                    if status == .authorizedWhenInUse || status == .authorizedAlways {
                        return self.requestLocationDirectly().asObservable()
                    } else {
                        return Observable.error(LocationError.permissionDenied)
                    }
                }
                .subscribe(
                    onNext: { location in
                        observer(.success(location))
                    },
                    onError: { error in
                        observer(.failure(error))
                    }
                )

            // 권한 요청 시작
            self.locationManager.requestWhenInUseAuthorization()
            return disposable
        }
    }

    // 직접적인 위치 요청 (권한이 있을 때만 호출)
    private func requestLocationDirectly() -> Single<CLLocation> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(LocationError.unknown))
                return Disposables.create()
            }

            // 최근 위치가 있으면 재사용 (30초 이내)
            if let recent = self.currentLocationRelay.value,
               abs(recent.timestamp.timeIntervalSinceNow) < 30 {
                observer(.success(recent))
                return Disposables.create()
            }

            // 새로운 위치 요청
            let disposable = self.currentLocation
                .compactMap { $0 }
                .take(1)
                .timeout(.seconds(10), scheduler: MainScheduler.instance)
                .subscribe(
                    onNext: { observer(.success($0)) },
                    onError: { _ in observer(.failure(LocationError.timeout)) }
                )

            self.locationManager.requestLocation()
            return disposable
        }
    }

    func openLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "위치 권한이 거부되었습니다. 설정에서 위치 권한을 허용해주세요."
        case .locationUnavailable:
            return "현재 위치를 찾을 수 없습니다."
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

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusRelay.accept(manager.authorizationStatus)
    }
}
