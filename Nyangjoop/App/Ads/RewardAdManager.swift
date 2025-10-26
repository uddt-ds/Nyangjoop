//
//  RewardAdManager.swift
//  Nyangjoop
//
//  Created by Lee on 10/17/25.
//

import GoogleMobileAds

protocol RewardAdManagerDelegate: AnyObject {
    func rewardAdDidLoad()
    func rewardAdDidFailToLoad(with error: Error)
    func rewardAdDidPresent()
    func rewardAdDidDismiss()
    func rewardAdDidFail(with error: Error)
    func userDidEarnReward(amount: Int)
    func shouldShowHouseAd(from viewController: UIViewController)
}

final class RewardAdManager: NSObject {
    static let shared = RewardAdManager()

    weak var delegate: RewardAdManagerDelegate?
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    private var isLoading = false
    private var hasRewarded = false
    private var loadRetryCount = 0
    private let maxRetryCount = 2
    weak var requestingViewController: UIViewController?
    var shouldShowHouseAdOnFailure = false

    private override init() {
        super.init()
    }

    func loadAd(with adUnitID: String) {
        guard !isLoading else { return }
        isLoading = true
        hasRewarded = false

        Task { @MainActor in
            do {
                self.rewardedInterstitialAd = try await RewardedInterstitialAd.load(
                    with: adUnitID,
                    request: Request()
                )

                self.rewardedInterstitialAd?.fullScreenContentDelegate = self
                self.isLoading = false
                self.loadRetryCount = 0
                self.delegate?.rewardAdDidLoad()
            } catch {
                self.isLoading = false
                
                if self.loadRetryCount < self.maxRetryCount {
                    self.loadRetryCount += 1
                    print("[RewardAdManager] 광고 로드 실패, 재시도 \(self.loadRetryCount)/\(self.maxRetryCount)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.loadAd(with: adUnitID)
                    }
                } else {
                    print("[RewardAdManager] 광고 로드 최종 실패")
                    self.loadRetryCount = 0
                    self.delegate?.rewardAdDidFailToLoad(with: error)
                    
                    if self.shouldShowHouseAdOnFailure, let viewController = self.requestingViewController {
                        print("[RewardAdManager] 하우스 광고 표시 요청")
                        self.delegate?.shouldShowHouseAd(from: viewController)
                        self.requestingViewController = nil
                        self.shouldShowHouseAdOnFailure = false
                    } else {
                        print("[RewardAdManager] 하우스 광고 스킵 (백그라운드 로드 또는 VC 없음)")
                        self.shouldShowHouseAdOnFailure = false
                    }
                }
            }
        }
    }

    func showAd(from viewController: UIViewController) {
        requestingViewController = viewController
        
        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            return
        }

        hasRewarded = false

        rewardedInterstitialAd.present(from: viewController) { [weak self] in
            guard let self else { return }
            
            guard !self.hasRewarded else {
                print("[RewardAdManager] 중복 보상 방지")
                return
            }
            
            self.hasRewarded = true
            let reward = rewardedInterstitialAd.adReward
            
            print("[RewardAdManager] 광고 보상 - amount: \(reward.amount.intValue)")
            self.delegate?.userDidEarnReward(amount: reward.amount.intValue)
        }
    }

    var isAdReady: Bool {
        return rewardedInterstitialAd != nil
    }

}

extension RewardAdManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        delegate?.rewardAdDidPresent()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        delegate?.rewardAdDidFail(with: error)
        rewardedInterstitialAd = nil
        hasRewarded = false
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        delegate?.rewardAdDidDismiss()
        rewardedInterstitialAd = nil
    }
}
