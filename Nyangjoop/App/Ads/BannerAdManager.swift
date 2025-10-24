import Foundation
import GoogleMobileAds
import UIKit

final class BannerAdManager: NSObject {
    static let shared = BannerAdManager()
    
    private var preloadedBannerView: BannerView?
    private var isPreloadedAdReady = false
    private var isPreloading = false
    private let testAdUnitID = AdConfig.bannerAdUnitID
    
    private override init() {
        super.init()
    }
    
    private func getAdaptiveAdSize(width: CGFloat) -> AdSize {
        return currentOrientationAnchoredAdaptiveBanner(width: width)
    }
    
    func preloadBannerAd(width: CGFloat) {
        guard preloadedBannerView == nil, !isPreloading else {
            print("[BannerAdManager] 배너 광고 이미 로드 중이거나 로드됨")
            return
        }
        
        isPreloading = true
        isPreloadedAdReady = false
        print("[BannerAdManager] 배너 광고 미리 로드 시작 - 너비: \(width)")
        
        let adaptiveSize = getAdaptiveAdSize(width: width)
        print("[BannerAdManager] 적응형 배너 크기: \(adaptiveSize.size)")
        
        let bannerView = BannerView()
        bannerView.frame = CGRect(x: 0, y: 0, width: adaptiveSize.size.width, height: adaptiveSize.size.height)
        bannerView.adUnitID = testAdUnitID
        bannerView.delegate = self
        bannerView.load(Request())
        
        preloadedBannerView = bannerView
    }
    
    func getBannerView(for viewController: UIViewController, width: CGFloat) -> (bannerView: BannerView, isReady: Bool) {
        if let preloaded = preloadedBannerView {
            print("[BannerAdManager] 미리 로드된 배너 사용 - 준비 상태: \(isPreloadedAdReady)")
            let banner = preloaded
            let ready = isPreloadedAdReady
            banner.rootViewController = viewController
            preloadedBannerView = nil
            isPreloadedAdReady = false
            isPreloading = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.preloadBannerAd(width: width)
            }
            
            return (banner, ready)
        } else {
            print("[BannerAdManager] 새 배너 생성")
            let adaptiveSize = getAdaptiveAdSize(width: width)
            let bannerView = BannerView()
            bannerView.frame = CGRect(x: 0, y: 0, width: adaptiveSize.size.width, height: adaptiveSize.size.height)
            bannerView.adUnitID = testAdUnitID
            bannerView.rootViewController = viewController
            bannerView.load(Request())
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.preloadBannerAd(width: width)
            }
            
            return (bannerView, false)
        }
    }
    
    var isReady: Bool {
        return preloadedBannerView != nil && isPreloadedAdReady
    }
}

extension BannerAdManager: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("[BannerAdManager] 배너 광고 로드 완료")
        isPreloading = false
        isPreloadedAdReady = true
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("[BannerAdManager] 배너 광고 로드 실패: \(error.localizedDescription)")
        isPreloading = false
        isPreloadedAdReady = false
        preloadedBannerView = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let width = UIScreen.main.bounds.width - 40
            self.preloadBannerAd(width: width)
        }
    }
}
