import Foundation

extension UserDefaults {
    private enum Keys {
        static let userAddress = "userAddress"
        static let churCount = "churCount"
        static let isFirstLaunch = "isFirstLaunch"
        static let catRegistrationCount = "catRegistrationCount"
        static let processedTxIds = "iap.processedTxIds"
        static let appAccountToken = "iap.appAccountToken"
        static let nickname = "nickname"
        static let hasSetNickname = "hasSetNickname"
    }
    
    var userAddress: String? {
        get {
            return string(forKey: Keys.userAddress)
        }
        set {
            set(newValue, forKey: Keys.userAddress)
        }
    }
    
    var churCount: Int {
        get {
            return integer(forKey: Keys.churCount)
        }
        set {
            set(newValue, forKey: Keys.churCount)
        }
    }
    
    var isFirstLaunch: Bool {
        get {
            return bool(forKey: Keys.isFirstLaunch)
        }
        set {
            set(newValue, forKey: Keys.isFirstLaunch)
        }
    }
    
    var catRegistrationCount: Int {
        get {
            return integer(forKey: Keys.catRegistrationCount)
        }
        set {
            set(newValue, forKey: Keys.catRegistrationCount)
        }
    }

    var processedTxIds: Set<String> {
        get {
            Set(stringArray(forKey: Keys.processedTxIds) ?? [])
        }
        set {
            set(Array(newValue), forKey: Keys.processedTxIds)
        }
    }

    var appAccountToken: UUID {
        get {
            if let str = string(forKey: Keys.appAccountToken), let user = UUID(uuidString: str) { return user }
            let user = UUID(); set(user.uuidString, forKey: Keys.appAccountToken)
            return user
        }
        set {
            set(newValue.uuidString, forKey: Keys.appAccountToken)
        }
    }

    var nickname: String {
        get {
            return string(forKey: Keys.nickname) ?? ""
        }
        set {
            set(newValue, forKey: Keys.nickname)
        }
    }

    var hasSetNickname: Bool {
        get {
            return bool(forKey: Keys.hasSetNickname)
        }
        set {
            set(newValue, forKey: Keys.hasSetNickname)
        }
    }
}

