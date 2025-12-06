//
//  ProfileViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 10/01/25.
//

import Foundation
import RxSwift
import RxCocoa

final class ProfileViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()
    private let realmManager = RealmManager.shared
    private let locationManager = LocationManager.shared

    private let greetMessages = GreetMessage.allCases.map { $0.rawValue }

    struct Input {
        let viewWillAppear: Observable<Void>
        let viewDidLoad: Observable<Void>
        let logoutTapped: Observable<Void>
    }
    
    struct Output {
        let registeredCatsCount: Driver<Int>
        let greetMessage: Driver<String>
        let photoCount: Driver<Int>
        let visitCount: Driver<Int>
        let achievements: Driver<[Achievement]>
        let showLogoutConfirm: Driver<Void>
    }
    
    struct Achievement {
        let type: AchievementType
        let title: String
        let description: String
        let imageName: String
        let isCompleted: Bool
    }
    
    func transform(_ input: Input) -> Output {
        let stats = input.viewWillAppear
            .map { _ -> (cats: Int, photos: Int, visits: Int) in
                let cats = RealmManager.shared.fetchAllCats()          // [Cat]
                            let visits = RealmManager.shared.fetchAllVisitLogs()   // [VisitLog]

                            // 위젯 데이터 동기화
                            WidgetSyncManager.updateWidgetStatsFromRealm()

                            return (cats.count, visits.count, visits.count)
            }
        
        let registeredCatsCount = stats
            .map { $0.cats }
            .asDriver(onErrorJustReturn: 0)
        
        let photoCount = stats
            .map { $0.photos }
            .asDriver(onErrorJustReturn: 0)
        
        let visitCount = stats
            .map { $0.visits }
            .asDriver(onErrorJustReturn: 0)
        
        let achievements = input.viewWillAppear
            .map { [weak self] _ -> [Achievement] in
                guard let self = self else { return [] }
                return self.getAchievements()
            }
            .asDriver(onErrorJustReturn: [])
        
        let showLogoutConfirm = input.logoutTapped
            .asDriver(onErrorDriveWith: .empty())

        let greetingMessage = input.viewDidLoad
            .map { [weak self] _ -> String in
                guard let self = self else { return "" }
                return self.greetMessages.randomElement() ?? "안녕하세요!"
            }
            .asDriver(onErrorJustReturn: "안녕하세요!")

        return Output(
            registeredCatsCount: registeredCatsCount,
            greetMessage: greetingMessage,
            photoCount: photoCount,
            visitCount: visitCount,
            achievements: achievements,
            showLogoutConfirm: showLogoutConfirm
        )
    }
    
    private func getAchievements() -> [Achievement] {
        let catCount = RealmManager.shared.getTotalCatCount()
        let photoCount = RealmManager.shared.getTotalPhotoCount()
        
        checkCurrentLocationAddress()
        
        let address = UserDefaults.standard.userAddress
        
        print("[ProfileViewModel] catCount: \(catCount), photoCount: \(photoCount), address: \(address ?? "nil")")
        
        let allAchievements = AchievementManager.shared.getAllAchievements(
            catCount: catCount,
            photoCount: photoCount,
            address: address
        )
        
        return allAchievements.map { achievement in
            Achievement(
                type: achievement.type,
                title: achievement.type.rawValue,
                description: achievement.type.description,
                imageName: achievement.type.imageName,
                isCompleted: achievement.isUnlocked
            )
        }
    }
    
    private func checkCurrentLocationAddress() {
        guard locationManager.isLocationEnabled else { return }
        
        locationManager.getCurrentLocation()
            .flatMap { location in
                self.locationManager.getAddressFromLocation(location)
            }
            .subscribe { address in
                print("[ProfileViewModel] 현재 주소: \(address)")
                UserDefaults.standard.userAddress = address
            } onFailure: { error in
                print("[ProfileViewModel] 주소 가져오기 실패: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
    }

}

enum GreetMessage: String, CaseIterable {
    case greet = "반가워요!"
    case hello = "안녕하세요?"
    case meet = "또 오셨네요?"
    case today = "오늘은 어떤 하루였나요?"
    case adventure = "고양이 찾으러 갈 준비되셨나요?"
    case stay = "기다렸어요"
    case wonder = "고양이가 기다리고 있지 않을까요?"
}
