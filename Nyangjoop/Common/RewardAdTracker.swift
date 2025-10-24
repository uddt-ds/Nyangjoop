import Foundation

final class RewardAdTracker {
    static let shared = RewardAdTracker()
    
    private let maxDailyAds = 4
    private let dateKey = "lastAdDate"
    private let countKey = "dailyAdCount"
    
    private init() {}
    
    var remainingAds: Int {
        return max(0, maxDailyAds - currentDailyCount)
    }
    
    var canShowAd: Bool {
        return remainingAds > 0
    }
    
    private var currentDailyCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = UserDefaults.standard.object(forKey: dateKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            
            if today == lastDay {
                return UserDefaults.standard.integer(forKey: countKey)
            }
        }
        
        return 0
    }
    
    func incrementAdCount() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = UserDefaults.standard.object(forKey: dateKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            
            if today == lastDay {
                let currentCount = UserDefaults.standard.integer(forKey: countKey)
                UserDefaults.standard.set(currentCount + 1, forKey: countKey)
            } else {
                UserDefaults.standard.set(today, forKey: dateKey)
                UserDefaults.standard.set(1, forKey: countKey)
            }
        } else {
            UserDefaults.standard.set(today, forKey: dateKey)
            UserDefaults.standard.set(1, forKey: countKey)
        }
    }
    
    func resetDailyCount() {
        UserDefaults.standard.removeObject(forKey: dateKey)
        UserDefaults.standard.removeObject(forKey: countKey)
    }
}
