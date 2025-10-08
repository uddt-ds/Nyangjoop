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
        let title: String
        let description: String
        let status: String
        let isCompleted: Bool
    }
    
    func transform(_ input: Input) -> Output {
        let stats = input.viewWillAppear
            .map { [weak self] _ -> (cats: Int, photos: Int, visits: Int) in
                guard let self = self else { return (0, 0, 0) }
                
                let cats = self.realmManager.fetchAllCats()
                let visits = self.realmManager.fetchAllVisitLogs()
                
                return (
                    cats: cats.count,
                    photos: visits.count, // 방문 로그 = 사진 개수
                    visits: visits.count
                )
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
        var achievements: [Achievement] = []
        
        // 모든 업적 준비중으로 변경
        achievements.append(Achievement(
            title: "첫 만남",
            description: "첫 고양이를 등록하세요",
            status: "준비중",
            isCompleted: false
        ))
        
        achievements.append(Achievement(
            title: "사진작가",
            description: "사진 100장 촬영",
            status: "준비중",
            isCompleted: false
        ))
        
        achievements.append(Achievement(
            title: "단골손님",
            description: "7일 연속 방문",
            status: "준비중",
            isCompleted: false
        ))
        
        achievements.append(Achievement(
            title: "고양이 집사",
            description: "고양이 10마리 등록",
            status: "준비중",
            isCompleted: false
        ))
        
        achievements.append(Achievement(
            title: "열정적인 집사",
            description: "총 500번 방문",
            status: "준비중",
            isCompleted: false
        ))
        
        return achievements
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
