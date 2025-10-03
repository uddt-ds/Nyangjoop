//
//  UIImage+Resize.swift
//  Nyangjoop
//
//  Created by Lee on 10/3/25.
//

import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
