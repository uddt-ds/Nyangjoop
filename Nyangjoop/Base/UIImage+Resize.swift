//
//  UIImage+Resize.swift
//  Nyangjoop
//
//  Created by Lee on 10/3/25.
//

import UIKit
import CoreGraphics

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func resizeIfNeeded(maxDimension: CGFloat) -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        
        let orientation = self.imageOrientation
        var width = CGFloat(cgImage.width)
        var height = CGFloat(cgImage.height)
        
        switch orientation {
        case .left, .right, .leftMirrored, .rightMirrored:
            swap(&width, &height)
        default:
            break
        }
        
        let maxSize = max(width, height)
        
        if maxSize <= maxDimension {
            return self
        }
        
        let scale = maxDimension / maxSize
        let newSize = CGSize(
            width: width * scale,
            height: height * scale
        )
        
        return resizeOptimized(to: newSize) ?? self
    }
    
    private func resizeOptimized(to targetSize: CGSize) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        
        let imageOrientation = self.imageOrientation
        
        switch imageOrientation {
        case .up:
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
            
        case .down:
            context.translateBy(x: targetSize.width, y: targetSize.height)
            context.rotate(by: .pi)
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
            
        case .left:
            context.translateBy(x: targetSize.width, y: 0)
            context.rotate(by: .pi / 2)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetSize.height, height: targetSize.width))
            
        case .right:
            context.translateBy(x: 0, y: targetSize.height)
            context.rotate(by: -.pi / 2)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetSize.height, height: targetSize.width))
            
        case .upMirrored:
            context.translateBy(x: targetSize.width, y: 0)
            context.scaleBy(x: -1, y: 1)
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
            
        case .downMirrored:
            context.translateBy(x: 0, y: targetSize.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
            
        case .leftMirrored:
            context.translateBy(x: targetSize.width, y: targetSize.height)
            context.rotate(by: -.pi / 2)
            context.scaleBy(x: 1, y: -1)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetSize.height, height: targetSize.width))
            
        case .rightMirrored:
            context.rotate(by: .pi / 2)
            context.scaleBy(x: 1, y: -1)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetSize.height, height: targetSize.width))
            
        @unknown default:
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
        }
        
        guard let scaledImage = context.makeImage() else { return nil }
        
        return UIImage(cgImage: scaledImage, scale: 1.0, orientation: .up)
    }
}
