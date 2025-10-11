import Foundation
import RxSwift
import RxCocoa

final class AchievementManager {
    static let shared = AchievementManager()
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "unlockedAchievements"
    
    private init() {}
    
    func checkAndUnlockAchievements(catCount: Int, photoCount: Int, address: String?) -> [AchievementType] {
        var newlyUnlocked: [AchievementType] = []
        
        for type in AchievementType.allCases {
            if !isAchievementUnlocked(type) && checkRequirement(type, catCount: catCount, photoCount: photoCount, address: address) {
                unlockAchievement(type)
                newlyUnlocked.append(type)
            }
        }
        
        return newlyUnlocked
    }
    
    func getAllAchievements(catCount: Int, photoCount: Int, address: String?) -> [Achievement] {
        checkAndUnlockAchievements(catCount: catCount, photoCount: photoCount, address: address)
        
        return AchievementType.allCases.map { type in
            let isUnlocked = checkRequirement(type, catCount: catCount, photoCount: photoCount, address: address)
            let unlockedDate = getUnlockedDate(type)
            return Achievement(type: type, isUnlocked: isUnlocked, unlockedDate: unlockedDate)
        }
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        let unlockedTypes = getUnlockedAchievementTypes()
        return unlockedTypes.map { type in
            Achievement(type: type, isUnlocked: true, unlockedDate: getUnlockedDate(type))
        }
    }
    
    private func checkRequirement(_ type: AchievementType, catCount: Int, photoCount: Int, address: String?) -> Bool {
        switch type.requirement {
        case .catCount(let required):
            return catCount >= required
        case .photoCount(let required):
            return photoCount >= required
        case .address(let required):
            return address?.contains(required) ?? false
        }
    }
    
    private func unlockAchievement(_ type: AchievementType) {
        var unlocked = getUnlockedAchievementTypes()
        if !unlocked.contains(type) {
            unlocked.append(type)
            saveUnlockedAchievements(unlocked)
            saveUnlockedDate(type, date: Date())
        }
    }
    
    private func isAchievementUnlocked(_ type: AchievementType) -> Bool {
        return getUnlockedAchievementTypes().contains(type)
    }
    
    private func getUnlockedAchievementTypes() -> [AchievementType] {
        guard let data = userDefaults.data(forKey: achievementsKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return decoded.compactMap { AchievementType(rawValue: $0) }
    }
    
    private func saveUnlockedAchievements(_ achievements: [AchievementType]) {
        let rawValues = achievements.map { $0.rawValue }
        if let encoded = try? JSONEncoder().encode(rawValues) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func getUnlockedDate(_ type: AchievementType) -> Date? {
        let key = "achievement_date_\(type.rawValue)"
        return userDefaults.object(forKey: key) as? Date
    }
    
    private func saveUnlockedDate(_ type: AchievementType, date: Date) {
        let key = "achievement_date_\(type.rawValue)"
        userDefaults.set(date, forKey: key)
    }
}
