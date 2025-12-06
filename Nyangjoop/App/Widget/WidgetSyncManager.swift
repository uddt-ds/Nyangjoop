//
//  WidgetSyncManager.swift
//  Nyangjoop
//
//  Created by Lee on 12/6/25.
//

import WidgetKit

enum WidgetSyncManager {
    static func updateWidgetStatsFromRealm() {
        let cats = RealmManager.shared.fetchAllCats()
        let visits = RealmManager.shared.fetchAllVisitLogs()

        let catCount = cats.count
        let visitCount = visits.count
        let achievement = AchievementManager.shared.getAllAchievements(catCount: catCount, photoCount: visitCount, address: nil)

        let medalCount = achievement.filter { $0.isUnlocked }.count

        let stats = WidgetStats(catCount: catCount,
                                visitCount: visitCount,
                                medalCount: medalCount)

        SharedDataManager.saveWidgetStats(stats)

        WidgetCenter.shared.reloadAllTimelines()
    }
}
