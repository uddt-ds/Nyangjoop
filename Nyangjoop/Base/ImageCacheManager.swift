//
//  ImageCacheManager.swift
//  Nyangjoop
//
//  Created by Lee on 11/25/25.
//

import UIKit

final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()

    private var sizeCache: [String: CGSize] = [:]
    private let sizeCacheLock = NSLock()

    private init() {
        cache.countLimit = 20
        cache.totalCostLimit = 30 * 1024 * 1024

        // 메모리 경고 시 캐시 정리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // 캐시로부터 이미지 가져오기
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    // 캐시에 이미지 저장
    func setImage(_ image: UIImage, forKey key: String) {
        guard let cgImage = image.cgImage else { return }

        let cost = cgImage.bytesPerRow * cgImage.height
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func setImageSize(_ size: CGSize, forKey key: String) {
        sizeCacheLock.lock()
        sizeCache[key] = size
        sizeCacheLock.unlock()
    }

    func getImageSize(forKey key: String) -> CGSize? {
        sizeCacheLock.lock()
        defer { sizeCacheLock.unlock() }
        return sizeCache[key]
    }

    // 캐시 삭제
    @objc func clearCache() {
        cache.removeAllObjects()

        sizeCacheLock.lock()
        sizeCache.removeAll()
        sizeCacheLock.unlock()

        print("ImageCacheManager 캐시 전체 삭제")
    }

    // 특정 이미지 삭제
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clearAllCaches() {
        clearCache()
    }
}
