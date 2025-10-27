//
//  AppLovinAdManager.swift
//  Nyangjoop
//
//  Created by Lee on 10/26/25.
//

import Foundation
import UIKit
import AppLovinSDK

protocol AppLovinInterstitialDelegate: AnyObject {
    func appLovinInterstitialDidLoad()
    func appLovinInterstitialDidFailToLoad(error: Error)
    func appLovinInterstitialDidPresent()
    func appLovinInterstitialDidDismiss()
    func appLovinInterstitialDidFailToPresent(error: Error)
}

final class AppLovinInterstitialAdManager: NSObject {

    weak var delegate: AppLovinInterstitialDelegate?

    private var interstitialAd: MAInterstitialAd?
    private let adUnitId: String
    private var isAdReady: Bool = false

    init(adUnitId: String) {
        self.adUnitId = adUnitId
        super.init()
        setupInterstitialAd()
    }

    private func setupInterstitialAd() {
        interstitialAd = MAInterstitialAd(adUnitIdentifier: adUnitId)
        interstitialAd?.delegate = self
    }

    func loadAd() {
        guard let interstitialAd = interstitialAd else {
            print("AppLovin 전면광고 인스턴스가 없습니다")
            return
        }

        isAdReady = false
        interstitialAd.load()
    }

    func show(from viewController: UIViewController) {
        guard let interstitialAd = interstitialAd else {
            print("AppLovin 전면광고 인스턴스가 없습니다")
            let error = NSError(
                domain: "AppLovinInterstitialAdManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Interstitial ad instance is nil"]
            )
            delegate?.appLovinInterstitialDidFailToPresent(error: error)
            return
        }

        guard isAdReady else {
            print("AppLovin 전면광고가 준비되지 않았습니다")
            let error = NSError(
                domain: "AppLovinInterstitialAdManager",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Ad is not ready"]
            )
            delegate?.appLovinInterstitialDidFailToPresent(error: error)
            return
        }

        interstitialAd.show()
    }

    func isReady() -> Bool {
        return isAdReady && interstitialAd?.isReady == true
    }

    func destroy() {
        interstitialAd?.delegate = nil
        interstitialAd = nil
        isAdReady = false
    }
}

// MARK: - MAAdDelegate

extension AppLovinInterstitialAdManager: MAAdDelegate {
    func didLoad(_ ad: MAAd) {
        print("AppLovin 전면광고 로드 성공")
        isAdReady = true
        delegate?.appLovinInterstitialDidLoad()
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        print("AppLovin 전면광고 로드 실패: \(error.message)")
        isAdReady = false

        let nsError = NSError(
            domain: "AppLovinInterstitialAdManager",
            code: error.code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: error.message]
        )
        delegate?.appLovinInterstitialDidFailToLoad(error: nsError)
    }

    func didDisplay(_ ad: MAAd) {
        print("AppLovin 전면광고 표시됨")
        delegate?.appLovinInterstitialDidPresent()
    }

    func didHide(_ ad: MAAd) {
        print("AppLovin 전면광고 닫힘")
        isAdReady = false
        delegate?.appLovinInterstitialDidDismiss()
    }

    func didClick(_ ad: MAAd) {
        print("AppLovin 전면광고 클릭됨")
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        print("AppLovin 전면광고 표시 실패: \(error.message)")
        isAdReady = false

        let nsError = NSError(
            domain: "AppLovinInterstitialAdManager",
            code: error.code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: error.message]
        )
        delegate?.appLovinInterstitialDidFailToPresent(error: nsError)
    }
}
