//
//  LocationManager.swift
//  Nyangjoop
//
//  Created by Lee on 10/17/25.
//

import Foundation

final class ChurService {
    static let shared = ChurService()
    
    private init() {}
    
    private let initialChurCount = 10
    private let catRegistrationCost = 1
    
    var currentChurCount: Int {
        return UserDefaults.standard.churCount
    }
    
    func initializeChurIfNeeded() {
        if !UserDefaults.standard.isFirstLaunch {
            UserDefaults.standard.churCount = initialChurCount
            UserDefaults.standard.isFirstLaunch = true
        }
    }
    
    func hasEnoughChurForRegistration() -> Bool {
        return currentChurCount >= catRegistrationCost
    }
    
    func deductChurForRegistration() throws {
        guard hasEnoughChurForRegistration() else {
            throw ChurError.insufficientChur
        }
        UserDefaults.standard.churCount -= catRegistrationCost
    }
    
    func addChur(amount: Int) {
        UserDefaults.standard.churCount += amount
    }
}

enum ChurError: Error, LocalizedError {
    case insufficientChur
    
    var errorDescription: String? {
        switch self {
        case .insufficientChur:
            return "츄르가 부족합니다. 고양이를 등록하려면 츄르 1개가 필요합니다."
        }
    }
}
