//
//  FileManager+ImageStorage.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import UIKit

extension FileManager {
    
    /// Documents 디렉토리 경로
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// 이미지를 Documents 디렉토리에 저장
    static func saveImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        let fileName = "cat_\(UUID().uuidString).jpg"
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: filePath)
            return fileName
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }
    
    /// Documents 디렉토리에서 이미지 불러오기
    static func loadImage(fileName: String) -> UIImage? {
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: filePath.path)
    }

    // 캐시를 사용해서 이미지 로드
    static func loadImageWithCache(fileName: String, targetSize: CGSize? = nil) -> UIImage? {

        let cacheKey: String
        if let targetSize = targetSize {
            cacheKey = "\(fileName)_\(Int(targetSize.width))x\(Int(targetSize.height))"
        } else {
            cacheKey = fileName
        }
        
        // 캐시된 이미지 있는지 확인, 있으면 cached된 이미지 Return
        if let cachedImage = ImageCacheManager.shared.getImage(forKey: cacheKey) {
            return cachedImage
        }

        let filePath = documentsDirectory.appendingPathComponent(fileName)

        // 디스크에서 이미지 로드
        guard let image = loadImageDownsampled(at: filePath, targetSize: targetSize) else {
            return nil
        }
        
        // 캐시에 저장
        ImageCacheManager.shared.setImage(image, forKey: cacheKey)
        return image
    }

    // 이미지 다운 샘플링
    private static func loadImageDownsampled(at url: URL, targetSize: CGSize?) -> UIImage? {
        guard let targetSize = targetSize, targetSize.width > 0, targetSize.height > 0 else {
            return UIImage(contentsOfFile: url.path)
        }

        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(targetSize.width, targetSize.height) * UIScreen.main.scale

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return UIImage(contentsOfFile: url.path)
        }

        return UIImage(cgImage: downsampledImage)
    }

    /// Documents 디렉토리에서 이미지 삭제
    @discardableResult
    static func deleteImage(fileName: String) -> Bool {
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: filePath)
            return true
        } catch {
            print("이미지 삭제 실패: \(error)")
            return false
        }
    }
    
    /// 파일명에서 전체 경로 생성
    static func getImagePath(fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent(fileName)
    }
}
