//
//  AnalyticsManager.swift
//  Nyangjoop
//
//  Created by Lee on 10/20/25.
//

import Foundation
import FirebaseAnalytics

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    func logDuplicateLogTabTap() {
        Analytics.logEvent("duplicate_log_tab_tap", parameters: [
            "current_screen": "log_screen",
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(eventName, parameters: parameters)
    }
}
