//
//  UIViewController+Alert.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import UIKit

extension UIViewController {
    
    /// 기본 에러 알림창
    func showErrorAlert(title: String = "오류", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    /// 성공 알림창
    func showSuccessAlert(title: String = "완료", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    /// 확인/취소 알림창
    func showConfirmAlert(title: String, message: String, confirmTitle: String = "확인", cancelTitle: String = "취소", onConfirm: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm()
        })
        
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            onCancel?()
        })
        
        present(alert, animated: true)
    }
    
    /// 위치 권한 설정 알림창
    func showLocationPermissionAlert(onOpenSettings: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "이 기능을 사용하려면 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            onOpenSettings?()
            LocationManager.shared.openLocationSettings()
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alert, animated: true)
    }
}
