//
//  RewardHelper.swift
//  Nyangjoop
//
//  Created by Lee on 10/17/25.
//

import Foundation
import GoogleMobileAds

class RewardHelper: NSObject, FullScreenContentDelegate {

    static let shared = RewardHelper()

    private var ad: RewardedInterstitialAd?
    private var isLoding = false

    func load() async {
        guard ad == nil, !isLoding else { return }
        isLoding = true
        defer { isLoding = false }

        do {
            ad = try await RewardedInterstitialAd.load(with: AdConfig.rewardInterstitialAdUnitID,
                                                       request: Request())
            ad?.fullScreenContentDelegate = self
            print("RewardedInterstitial loaded")
        } catch {
            ad = nil
            print("Failed to load: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func present(from host: UIViewController, onEarn: @escaping (AdReward) -> Void) -> Bool {
        guard let ad else {
            print("[Rewarded] not ready")
            Task { await load() }
            return false
        }

        let top = host.topMost()
        ad.present(from: top) {
            onEarn(ad.adReward)
        }
        return true
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        self.ad = nil
        Task { await self.load() }
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        print("Present failed: \(error.localizedDescription)")
        self.ad = nil
        Task { await self.load()  }
    }
}
