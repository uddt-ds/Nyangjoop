//
//  HomeViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let menuToggleTapped: Observable<Void>
        let storeToggleTapped: Observable<Void>
        let galleryToggleTapped: Observable<Void>
        let currentLocationTapped: Observable<Void>
        let homeButtonTapped: Observable<Void>
        let catRegisterTapped: Observable<Void>
        let logRecordTapped: Observable<Void>
        let profileTapped: Observable<Void>
    }

    struct Output {
        let isMenuExpanded: Driver<Bool>
        let showStoreMarkers: Driver<Bool>
        let showGalleryMarkers: Driver<Bool>
        let navigateToCatRegister: Driver<Void>
        let navigateToLogRecord: Driver<Void>
        let navigateToProfile: Driver<Void>
    }

    func transform(_ input: Input) -> Output {
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

        input.currentLocationTapped
            .subscribe { _ in
                print("눌렸습니다")
            }
            .disposed(by: disposeBag)

        input.homeButtonTapped
            .subscribe { _ in
                print("홈 버튼 눌림")
            }
            .disposed(by: disposeBag)

        let navigateToCatRegister = input.catRegisterTapped.asDriver(onErrorJustReturn: ())
        let navigateToLogRecord = input.logRecordTapped.asDriver(onErrorJustReturn: ())
        let navigateToProfile = input.profileTapped.asDriver(onErrorJustReturn: ())

        return Output(
            isMenuExpanded: isMenuExpanded,
            showStoreMarkers: showStoreMarkers,
            showGalleryMarkers: showGalleryMarkers,
            navigateToCatRegister: navigateToCatRegister,
            navigateToLogRecord: navigateToLogRecord,
            navigateToProfile: navigateToProfile
        )
    }
}
