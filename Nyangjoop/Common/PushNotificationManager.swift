import UIKit
import UserNotifications

final class PushNotificationManager {

    static let shared = PushNotificationManager()
    
    private init() {}
    
    enum NotificationType: String {
        case achievement = "ACHIEVEMENT"
        
        var title: String {
            switch self {
            case .achievement:
                return "획득한 칭호를 확인해보세요"
            }
        }
    }
    
    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String,
              let type = NotificationType(rawValue: typeString) else {
            return
        }
        
        switch type {
        case .achievement:
            navigateToProfile()
        }
    }
    
    private func navigateToProfile() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootViewController = window.rootViewController else {
                return
            }
            
            self.findAndPresentProfile(from: rootViewController)
        }
    }
    
    private func findAndPresentProfile(from viewController: UIViewController) {
        if let presented = viewController.presentedViewController {
            findAndPresentProfile(from: presented)
            return
        }
        
        if let tabBarController = viewController as? CustomTabBarController {
            guard let firstViewController = tabBarController.children.first,
                  let navigationController = firstViewController as? UINavigationController else {
                return
            }
            
            if navigationController.topViewController is ProfileViewController {
                return
            }
            
            navigationController.popToRootViewController(animated: false)
            let profileVC = ProfileViewController()
            navigationController.pushViewController(profileVC, animated: true)
            
        } else if let navigationController = viewController as? UINavigationController {
            if navigationController.topViewController is ProfileViewController {
                return
            }
            
            navigationController.popToRootViewController(animated: false)
            let profileVC = ProfileViewController()
            navigationController.pushViewController(profileVC, animated: true)
        }
    }
}

extension PushNotificationManager {
#if DEBUG
    static func sendTestAchievementNotification() {
        let content = UNMutableNotificationContent()
        content.title = "냥줍"
        content.body = "획득한 칭호를 확인해보세요"
        content.sound = .default
        content.userInfo = ["type": NotificationType.achievement.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("테스트 푸시 알림 전송 실패: \(error.localizedDescription)")
            } else {
                print("테스트 푸시 알림 전송 성공")
            }
        }
    }
#endif
}
