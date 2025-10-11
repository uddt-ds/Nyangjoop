import Foundation

extension UserDefaults {
    private enum Keys {
        static let userAddress = "userAddress"
    }
    
    var userAddress: String? {
        get {
            return string(forKey: Keys.userAddress)
        }
        set {
            set(newValue, forKey: Keys.userAddress)
        }
    }
}
