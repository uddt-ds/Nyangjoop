//
//  LocationManager.swift
//  Nyangjoop
//
//  Created by Lee on 10/17/25.
//

import Foundation
import UIKit

final class AdTriggerService {
    static let shared = AdTriggerService()

    private let adManager: HybridInterstitialAdManager
    private let triggerInterval = 4

    private let queue = DispatchQueue(label: "com.nyangjoop.adTrigger")

    private init() {
        // 전면광고 미사용 처리 (광고 필요 시 주석 해제)
        adManager = HybridInterstitialAdManager(
            admobAdUnitId: "", // AdMob 미사용
            appLovinAdUnitId: "" // AppLovin 미사용
        )
        // 광고 로드 미사용
        // adManager.loadAd()
    }
    
    func incrementRegistrationCount() {
        queue.sync {
            UserDefaults.standard.catRegistrationCount += 1
            print("[AdTriggerService] 등록 횟수: \(UserDefaults.standard.catRegistrationCount)")
        }
    }
    
    func checkAndShowAdIfNeeded(from viewController: UIViewController, completion: @escaping () -> Void) {
        // 전면광고 미사용 처리 (광고 필요 시 주석 해제)
        print("[AdTriggerService] 전면광고 미사용 - 바로 completion 호출")
        completion()

        /* 광고 필요 시 아래 주석 해제
        if InAppPurchaseManager.shared.hasRemovedAds {
            print("[AdTriggerService] 광고 제거 구매 완료 - 광고 스킵")
            completion()
            return
        }

        let currentCount = UserDefaults.standard.catRegistrationCount

        print("[AdTriggerService] 현재 등록 횟수: \(currentCount), 다음 광고: \(triggerInterval)의 배수")

        if currentCount > 0 && currentCount % triggerInterval == 0 {
            print("[AdTriggerService] 전면광고 표시 조건 충족")

            if adManager.isReady() {
                print("[AdTriggerService] 전면광고 표시")

                // HybridInterstitialAdManager의 delegate 설정
                adManager.delegate = self
                adManager.show(from: viewController)

                // completion은 delegate에서 호출됨
                self.adCompletionHandler = completion
            } else {
                print("[AdTriggerService] 전면광고 준비 안됨, 다음에 표시")
                adManager.loadAd()
                completion()
            }
        } else {
            print("[AdTriggerService] 전면광고 표시 조건 미충족")
            completion()
        }
        */
    }

    private var adCompletionHandler: (() -> Void)?
    
    func resetCount() {
        UserDefaults.standard.catRegistrationCount = 0
    }
}

// MARK: - HybridInterstitialAdManagerDelegate (광고 미사용 처리 - 광고 필요 시 주석 해제)
/*
extension AdTriggerService: HybridInterstitialAdManagerDelegate {
    func hybridInterstitialDidLoad(from source: InterstitialAdSource) {
        print("[AdTriggerService] 광고 로드 완료 - source: \(source)")
    }

    func hybridInterstitialDidFailToLoad() {
        print("[AdTriggerService] 모든 광고 로드 실패")
    }

    func hybridInterstitialDidPresent(from source: InterstitialAdSource) {
        print("[AdTriggerService] 광고 표시됨 - source: \(source)")
    }

    func hybridInterstitialDidDismiss(from source: InterstitialAdSource) {
        print("[AdTriggerService] 광고 닫힘 - source: \(source)")

        // 다음 광고 미리 로드
        adManager.loadAd()

        // completion 호출
        adCompletionHandler?()
        adCompletionHandler = nil
    }

    func hybridInterstitialDidFailToPresent(error: Error) {
        print("[AdTriggerService] 광고 표시 실패: \(error.localizedDescription)")

        // completion 호출
        adCompletionHandler?()
        adCompletionHandler = nil
    }
}
*/
