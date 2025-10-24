//
//  InterstitialAdManager.swift
//  Nyangjoop
//
//  Created by Lee on 10/16/25.
//

import UIKit
import GoogleMobileAds

final class InterstitialAdManager: NSObject {
    static let shared = InterstitialAdManager()

    private var interstitialAd: InterstitialAd?
    private var isLoading = false
    private var onAdDismissed: (() -> Void)?
    private var isAdPresenting = false
    private var shouldReloadOnForeground = false
    private var isReloadingFromForeground = false

    private override init() {
        super.init()
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        if isAdPresenting {
            shouldReloadOnForeground = true
            print("전면 광고 표시 중 백그라운드 전환 감지 - 포그라운드 복귀 시 재로드 예정")
        }
    }

    @objc private func appWillEnterForeground() {
        if shouldReloadOnForeground {
            shouldReloadOnForeground = false
            isReloadingFromForeground = true
            interstitialAd = nil
            loadInterstitialAd()
            print("포그라운드 복귀 - 전면 광고 재로드 시작")
        }
    }

    func loadInterstitialAd() {
        guard !isLoading else {
            print("이미 광고를 로드 중입니다")
            return
        }

        isLoading = true

        let adUnitID = AdConfig.interstitialAdUnitID

        InterstitialAd.load(with: adUnitID,
                            request: Request()) { [weak self] ad, error in
            guard let self else { return }
            self.isLoading = false

            if let error {
                print("전면 광고 로드 실패: \(error.localizedDescription)")
                self.interstitialAd = nil
                return
            }

            print("전면 광고 로드 성공")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    func showInterstitialAd(from viewController: UIViewController, onDismissed: (() -> Void)? = nil) {
        self.onAdDismissed = onDismissed

        guard let interstitialAd = interstitialAd else {
            print("전면 광고가 준비되지 않았습니다")
            loadInterstitialAd()
            onDismissed?()
            return
        }

        interstitialAd.present(from: viewController)
    }

    var isReady: Bool {
        return interstitialAd != nil
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: any FullScreenPresentingAd) {
        print("전면 광고 노출됨")
    }

    func adDidRecordClick(_ ad: any FullScreenPresentingAd) {
        print("전면 광고 클릭됨")
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        print("전면 광고 표시 실패: \(error.localizedDescription)")
        onAdDismissed?()
        onAdDismissed = nil

        interstitialAd = nil
        loadInterstitialAd()
    }

    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        print("전면 광고 표시될 예정")
        isAdPresenting = true
    }

    func adWillDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        print("전면 광고 닫힐 예정")
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        print("전면 광고 닫힘")
        isAdPresenting = false

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onAdDismissed?()
            self.onAdDismissed = nil
        }

        if isReloadingFromForeground {
            isReloadingFromForeground = false
            print("포그라운드 복귀로 인한 dismiss - 재로드 스킵")
        } else {
            interstitialAd = nil
            loadInterstitialAd()
        }
    }
}
