//
//  HomeViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import Foundation
import RxSwift
import RxCocoa
import MapKit

final class HomeViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()

    private let locationManager = LocationManager.shared
    private let realmManager = RealmManager.shared

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let menuToggleTapped: Observable<Void>
        let storeToggleTapped: Observable<Void>
        let galleryToggleTapped: Observable<Void>
        let currentLocationTapped: Observable<Void>
        let profileTapped: Observable<Void>
        let catAnnotationTapped: Observable<Cat>
    }

    struct Output {
        let cats: Driver<[Cat]>
        let isMenuExpanded: Driver<Bool>
        let showStoreMarkers: Driver<Bool>
        let showGalleryMarkers: Driver<Bool>
        let locationError: Driver<String>
        let currentLocation: Driver<CLLocation?>
        let moveToCurrentLocation: Driver<CLLocation>
        let showLocationPermissionAlert: Driver<Void>
        let showCatDetail: Driver<Cat>
        let navigateToProfile: Driver<Void>
    }

    func transform(_ input: Input) -> Output {

        let cats = Observable
            .merge(input.viewDidLoad, input.viewWillAppear)
            .withUnretained(self)
            .map { owner, _ -> [Cat] in
                let results = owner.realmManager.fetchAllCats()
                return Array(results)
            }
            .asDriver(onErrorJustReturn: [])

        let isMenuExpanded = input.menuToggleTapped
            .scan(false) { currentState, _ in !currentState }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        let showStoreMarkers = input.storeToggleTapped
            .scan(false) { currentState, _ in !currentState }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        let showGalleryMarkers = input.galleryToggleTapped
            .scan(false) { currentState, _ in !currentState }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        let currentLocationResult = input.currentLocationTapped
            .flatMap { [weak self] _ -> Observable<Result<CLLocation, LocationError>> in
                guard let self = self else {
                    return Observable.just(.failure(.unknown))
                }

                return self.locationManager.getCurrentLocation()
                    .asObservable()
                    .map { Result.success($0) }
                    .catch { error in
                        return Observable.just(.failure(error as? LocationError ?? .unknown))
                    }
            }
            .share()

        let moveToCurrentLocation = currentLocationResult
            .compactMap { result in
                if case .success(let location) = result {
                    return location
                }
                return nil
            }
            .asDriver(onErrorJustReturn: CLLocation(latitude: 37.5665, longitude: 126.9780))

        let locationError = currentLocationResult
            .compactMap { result in
                if case .failure(let error) = result {
                    return error.errorDescription
                }
                return nil
            }
            .asDriver(onErrorJustReturn: "위치를 가져올 수 없습니다")

        let showLocationPermissionAlert = currentLocationResult
            .compactMap { result in
                if case .failure(let error) = result, error == .permissionDenied {
                    return ()
                }
                return nil
            }
            .asDriver(onErrorJustReturn: ())

        let currentLocation = locationManager.currentLocation
            .asDriver(onErrorJustReturn: nil)

        let showCatDetail = input.catAnnotationTapped
            .asDriver(onErrorJustReturn: Cat())

        let navigateToProfile = input.profileTapped.asDriver(onErrorJustReturn: ())

        return Output(cats: cats,
                      isMenuExpanded: isMenuExpanded,
                      showStoreMarkers: showStoreMarkers,
                      showGalleryMarkers: showGalleryMarkers,
                      locationError: locationError,
                      currentLocation: currentLocation,
                      moveToCurrentLocation: moveToCurrentLocation,
                      showLocationPermissionAlert: showLocationPermissionAlert,
                      showCatDetail: showCatDetail,
                      navigateToProfile: navigateToProfile
                    )
    }
}
