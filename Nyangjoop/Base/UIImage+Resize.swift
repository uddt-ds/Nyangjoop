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
    
    func resizeIfNeeded(maxDimension: CGFloat) -> UIImage {
        let maxSize = max(size.width, size.height)
        
        if maxSize <= maxDimension {
            return self
        }
        
        let scale = maxDimension / maxSize
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
