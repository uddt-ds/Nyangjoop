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
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let logoutTapped: Observable<Void>
    }
    
    struct Output {
        let registeredCatsCount: Driver<Int>
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
        
        return Output(
            registeredCatsCount: registeredCatsCount,
            photoCount: photoCount,
            visitCount: visitCount,
            achievements: achievements,
            showLogoutConfirm: showLogoutConfirm
        )
    }
    
    private func getAchievements() -> [Achievement] {
        let cats = realmManager.fetchAllCats()
        let visits = realmManager.fetchAllVisitLogs()
        
        let catCount = cats.count
        let visitCount = visits.count
        
        var achievements: [Achievement] = []
        
        // 첫 만남
        achievements.append(Achievement(
            title: "첫 만남",
            description: "첫 고양이를 등록하세요",
            status: catCount >= 1 ? "완료" : "미완료",
            isCompleted: catCount >= 1
        ))
        
        // 사진작가
        achievements.append(Achievement(
            title: "사진작가",
            description: "사진 100장 촬영",
            status: visitCount >= 100 ? "완료" : "\(visitCount)/100",
            isCompleted: visitCount >= 100
        ))
        
        // 단골손님
        let consecutiveDays = calculateConsecutiveVisitDays()
        achievements.append(Achievement(
            title: "단골손님",
            description: "7일 연속 방문",
            status: consecutiveDays >= 7 ? "완료" : "\(consecutiveDays)/7일",
            isCompleted: consecutiveDays >= 7
        ))
        
        // 고양이 집사
        achievements.append(Achievement(
            title: "고양이 집사",
            description: "고양이 10마리 등록",
            status: catCount >= 10 ? "완료" : "\(catCount)/10마리",
            isCompleted: catCount >= 10
        ))
        
        // 열정적인 집사
        achievements.append(Achievement(
            title: "열정적인 집사",
            description: "총 500번 방문",
            status: visitCount >= 500 ? "완료" : "\(visitCount)/500회",
            isCompleted: visitCount >= 500
        ))
        
        return achievements
    }
    
    private func calculateConsecutiveVisitDays() -> Int {
        let visits = realmManager.fetchAllVisitLogs()
        
        guard !visits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = visits
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
        
        var consecutiveDays = 1
        var maxConsecutiveDays = 1
        
        for i in 1..<sortedDates.count {
            let currentDay = sortedDates[i]
            let previousDay = sortedDates[i-1]
            
            if let dayDifference = calendar.dateComponents([.day], from: currentDay, to: previousDay).day,
               dayDifference == 1 {
                consecutiveDays += 1
                maxConsecutiveDays = max(maxConsecutiveDays, consecutiveDays)
            } else if currentDay != previousDay {
                consecutiveDays = 1
            }
        }
        
        return maxConsecutiveDays
    }
}
