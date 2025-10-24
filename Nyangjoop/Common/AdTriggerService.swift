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
    
    private let adManager = InterstitialAdManager.shared
    private let triggerInterval = 4
    
    private init() {
        adManager.loadInterstitialAd()
    }
    
    func incrementRegistrationCount() {
        UserDefaults.standard.catRegistrationCount += 1
        print("[AdTriggerService] 등록 횟수: \(UserDefaults.standard.catRegistrationCount)")
    }
    
    func checkAndShowAdIfNeeded(from viewController: UIViewController, completion: @escaping () -> Void) {
        let currentCount = UserDefaults.standard.catRegistrationCount
        
        print("[AdTriggerService] 현재 등록 횟수: \(currentCount), 다음 광고: \(triggerInterval)의 배수")
        
        if currentCount > 0 && currentCount % triggerInterval == 0 {
            print("[AdTriggerService] 전면광고 표시 조건 충족")
            
            if adManager.isReady {
                print("[AdTriggerService] 전면광고 표시")
                adManager.showInterstitialAd(from: viewController) {
                    completion()
                }
            } else {
                print("[AdTriggerService] 전면광고 준비 안됨, 다음에 표시")
                adManager.loadInterstitialAd()
                completion()
            }
        } else {
            print("[AdTriggerService] 전면광고 표시 조건 미충족")
            completion()
        }
    }
    
    func resetCount() {
        UserDefaults.standard.catRegistrationCount = 0
    }
}
