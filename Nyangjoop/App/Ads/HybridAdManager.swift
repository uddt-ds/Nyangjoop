//
//  HybridAdManager.swift
//  Nyangjoop
//
//  Created by Lee on 10/26/25.
//

import UIKit
import GoogleMobileAds

enum InterstitialAdSource {
    case admob
    case appLovin
}

protocol HybridInterstitialAdManagerDelegate: AnyObject {
    func hybridInterstitialDidLoad(from source: InterstitialAdSource)
    func hybridInterstitialDidFailToLoad()
    func hybridInterstitialDidPresent(from source: InterstitialAdSource)
    func hybridInterstitialDidDismiss(from source: InterstitialAdSource)
    func hybridInterstitialDidFailToPresent(error: Error)
}

final class HybridInterstitialAdManager: NSObject {

    weak var delegate: HybridInterstitialAdManagerDelegate?

    private var admobInterstitial: InterstitialAd?
    private var appLovinManager: AppLovinInterstitialAdManager?
    private var currentSource: InterstitialAdSource?

    private let admobAdUnitId: String
    private let appLovinAdUnitId: String

    private var isLoading: Bool = false
    private weak var presentingViewController: UIViewController?

    init(admobAdUnitId: String, appLovinAdUnitId: String) {
        self.admobAdUnitId = admobAdUnitId
        self.appLovinAdUnitId = appLovinAdUnitId
        super.init()
    }

    func loadAd() {
        guard !isLoading else {
            print("이미 광고 로딩 중입니다")
            return
        }

        isLoading = true
        loadAdMobAd()
    }

    func show(from viewController: UIViewController) {
        guard !isLoading else {
            print("광고가 아직 로딩 중입니다")
            return
        }

        presentingViewController = viewController

        if let admobInterstitial = admobInterstitial {
            admobInterstitial.present(from: viewController)
        } else if let appLovinManager = appLovinManager {
            appLovinManager.show(from: viewController)

        } else {
            print("표시할 광고가 없습니다")
            delegate?.hybridInterstitialDidFailToPresent(
                error: NSError(domain: "HybridInterstitialAdManager",
                             code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "No ad available"])
            )
        }
    }

    func isReady() -> Bool {
        return admobInterstitial != nil || appLovinManager?.isReady() == true
    }

    private func loadAdMobAd() {
        print("AdMob 전면광고 로드 시도")

        let request = Request()
        InterstitialAd.load(with: admobAdUnitId, request: request) { [weak self] ad, error in
            guard let self = self else { return }

            self.isLoading = false

            if let error = error {
                print("AdMob 전면광고 로드 실패: \(error.localizedDescription)")
                self.loadAppLovinAd()
                return
            }

            guard let ad = ad else {
                print("AdMob 전면광고 로드 실패: ad is nil")
                self.loadAppLovinAd()
                return
            }

            print("AdMob 전면광고 로드 성공")
            self.admobInterstitial = ad
            self.admobInterstitial?.fullScreenContentDelegate = self
            self.currentSource = .admob
            self.delegate?.hybridInterstitialDidLoad(from: .admob)
        }
    }

    private func loadAppLovinAd() {
        print("AppLovin 전면광고 로드 시도")

        let appLovinManager = AppLovinInterstitialAdManager(adUnitId: appLovinAdUnitId)
        appLovinManager.delegate = self
        self.appLovinManager = appLovinManager

        appLovinManager.loadAd()
    }

    func destroy() {
        admobInterstitial = nil
        appLovinManager?.destroy()
        appLovinManager = nil
        currentSource = nil
        isLoading = false
        presentingViewController = nil
    }
}

// MARK: - GADFullScreenContentDelegate

extension HybridInterstitialAdManager: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("AdMob 전면광고 노출 기록")
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("AdMob 전면광고 클릭")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdMob 전면광고 표시 실패: \(error.localizedDescription)")
        admobInterstitial = nil
        delegate?.hybridInterstitialDidFailToPresent(error: error)
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdMob 전면광고 표시 시작")
        delegate?.hybridInterstitialDidPresent(from: .admob)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdMob 전면광고 닫힘")
        admobInterstitial = nil
        delegate?.hybridInterstitialDidDismiss(from: .admob)
    }
}

// MARK: - AppLovinInterstitialDelegate

extension HybridInterstitialAdManager: AppLovinInterstitialDelegate {
    func appLovinInterstitialDidLoad() {
        print("AppLovin 전면광고 로드 성공")
        isLoading = false
        currentSource = .appLovin
        delegate?.hybridInterstitialDidLoad(from: .appLovin)
    }

    func appLovinInterstitialDidFailToLoad(error: Error) {
        print("AppLovin 전면광고 로드 실패: \(error.localizedDescription)")
        isLoading = false
        delegate?.hybridInterstitialDidFailToLoad()
    }

    func appLovinInterstitialDidPresent() {
        print("AppLovin 전면광고 표시")
        delegate?.hybridInterstitialDidPresent(from: .appLovin)
    }

    func appLovinInterstitialDidDismiss() {
        print("AppLovin 전면광고 닫힘")
        appLovinManager = nil
        delegate?.hybridInterstitialDidDismiss(from: .appLovin)
    }

    func appLovinInterstitialDidFailToPresent(error: Error) {
        print("AppLovin 전면광고 표시 실패: \(error.localizedDescription)")
        delegate?.hybridInterstitialDidFailToPresent(error: error)
    }
}
