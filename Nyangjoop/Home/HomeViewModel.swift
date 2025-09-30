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
    private let networkManager = NetworkManager.shared

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
        let showGalleryMarkers: Driver<Bool>
        let locationError: Driver<String>
        let moveToCurrentLocation: Driver<CLLocation>
        let showLocationPermissionAlert: Driver<Void>
        let showCatDetail: Driver<Cat>
        let showProfileView: Driver<Void>
        let storeData: Driver<[MarketModel]>
        let isShowingStores: Driver<Bool>
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

        let showGalleryMarkers = input.galleryToggleTapped
            .scan(false) { currentState, _ in !currentState }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        // 현위치 버튼 탭 시 권한 요청 포함 (requestPermissionIfNeeded: true)
        let currentLocationResult = input.currentLocationTapped
            .flatMap { [weak self] _ -> Observable<Result<CLLocation, LocationError>> in
                guard let self = self else {
                    return Observable.just(.failure(.unknown))
                }

                return self.locationManager.getCurrentLocation(requestPermissionIfNeeded: true)
                    .asObservable()
                    .map { Result.success($0) }
                    .catch { error in
                        return Observable.just(.failure(error as? LocationError ?? .unknown))
                    }
            }
            .share()

        // 성공한 경우에만 위치 이동
        let moveToCurrentLocation = currentLocationResult
            .compactMap { result -> CLLocation? in
                if case .success(let location) = result {
                    print("현재 위치로 이동: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    return location
                }
                return nil
            }
            .asDriver(onErrorDriveWith: .empty()) // 에러 시에는 아무것도 emit하지 않음

        // 에러 메시지 (권한 거부 제외)
        let locationError = currentLocationResult
            .compactMap { result -> String? in
                if case .failure(let error) = result, error != .permissionDenied {
                    print("위치 에러: \(error)")
                    return error.errorDescription
                }
                return nil
            }
            .asDriver(onErrorJustReturn: "위치를 가져올 수 없습니다")

        // 권한 거부 시에만 권한 알림창 표시
        let showLocationPermissionAlert = currentLocationResult
            .compactMap { result -> Void? in
                if case .failure(let error) = result, error == .permissionDenied {
                    print("권한 거부됨 - 설정 알림창 표시")
                    return ()
                }
                return nil
            }
            .asDriver(onErrorJustReturn: ())

        let showCatDetail = input.catAnnotationTapped
            .asDriver(onErrorJustReturn: Cat())

        let isShowingStores = input.storeToggleTapped
            .scan(false) { currentState, _ in !currentState }
            .startWith(false)
            .share()

        let storeData = input.storeToggleTapped
            .withLatestFrom(Observable.combineLatest(isShowingStores, currentLocationResult))
            .filter { isShowing, _ in isShowing }
            .compactMap{ _, result -> CLLocationCoordinate2D? in
                return try? result.get().coordinate
            }
            .flatMapLatest { [weak self] coordinate -> Single<[MarketModel]> in
                guard let self else { return .just([]) }

                return self.networkManager.fetchData(
                    lat: coordinate.latitude,
                    lon: coordinate.longitude
                )
                .map { result in
                    switch result {
                    case .success(let markets):
                        return markets
                    case .failure(let error):
                        print("검색 실패: \(error.message)")
                        return []
                    }
                }
            }
            .asDriver(onErrorJustReturn: [])

        let showProfileView = input.profileTapped
            .asDriver(onErrorJustReturn: ())


        return Output(cats: cats,
                      isMenuExpanded: isMenuExpanded,
                      showGalleryMarkers: showGalleryMarkers,
                      locationError: locationError,
                      moveToCurrentLocation: moveToCurrentLocation,
                      showLocationPermissionAlert: showLocationPermissionAlert,
                      showCatDetail: showCatDetail,
                      showProfileView: showProfileView,
                      storeData: storeData,
                      isShowingStores: isShowingStores.asDriver(onErrorJustReturn: false)
                    )
    }
}
