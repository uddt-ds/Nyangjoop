//
//  SharedDataManager.swift
//  Nyangjoop
//
//  Created by Lee on 12/6/25.
//

import Foundation

struct WidgetStats {
    let catCount: Int
    let visitCount: Int
    let medalCount: Int
}

struct SharedDataManager {

    private enum Key: String {
        case catCount = "widgetCatCount"
        case visitCount = "widgetVisitCount"
        case medalCount = "widgetMedalCount"
    }

    private static let suiteName: String = {
        let bundle = Bundle.main

        if let id = bundle.object(forInfoDictionaryKey: "AppGroupID") as? String,
           !id.isEmpty {
            return id
        }

        return "group.com.jean.NyangJoop"
    }()

    private static var defaults: UserDefaults? {
       UserDefaults(suiteName: suiteName)
    }

    static func saveWidgetStats(_ stats: WidgetStats) {
        defaults?.set(stats.catCount, forKey: Key.catCount.rawValue)
        defaults?.set(stats.visitCount, forKey: Key.visitCount.rawValue)
        defaults?.set(stats.medalCount, forKey: Key.medalCount.rawValue)
    }

    static func loadWidgetStats() -> WidgetStats {
        let cat = defaults?.integer(forKey: Key.catCount.rawValue) ?? 0
        let visit = defaults?.integer(forKey: Key.visitCount.rawValue) ?? 0
        let medal = defaults?.integer(forKey: Key.medalCount.rawValue) ?? 0

        return WidgetStats(catCount: cat, visitCount: visit, medalCount: medal)
    }
}
