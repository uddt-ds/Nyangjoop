//
//  AppFont.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import UIKit

enum FontSystem {
    case main
    case sub
    case body
    case caption

    var font: UIFont {

        switch self {
        case .main:
            return UIFont(name: FontName.main.name, size: FontName.main.size) ?? .systemFont(ofSize: FontName.main.size)
        case .sub:
            return UIFont(name: FontName.sub.name, size: FontName.sub.size) ?? .systemFont(ofSize: FontName.sub.size)
        case .body:
            return UIFont(name: FontName.body.name, size: FontName.body.size) ?? .systemFont(ofSize: FontName.body.size)
        case .caption:
            return UIFont(name: FontName.caption.name, size: FontName.caption.size) ?? .systemFont(ofSize: FontName.caption.size)
        }
    }
}

enum FontName {
    case main
    case sub
    case body
    case caption

    var name: String {
        return "MemomentKkukkukkR"
    }

    var size: CGFloat {
        switch self {
        case .main:
            return 20
        case .sub:
            return 18
        case .body:
            return 16
        case .caption:
            return 12
        }
    }
}
