//
//  UIViewController+Extension.swift
//  Nyangjoop
//
//  Created by Lee on 10/17/25.
//

import UIKit

extension UIViewController {
    func topMost() -> UIViewController {
        var top: UIViewController = self
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}
