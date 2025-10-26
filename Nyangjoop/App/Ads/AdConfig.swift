//
//  AdConfig.swift
//  Nyangjoop
//
//  Created by Lee on 10/23/25.
//

import Foundation

enum AdConfig {
    static var bannerAdUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdBannerUnitID") as? String ?? ""
    }

    static var rewardInterstitialAdUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdRewardInterstitialUnitID") as? String ?? ""
    }

    static var interstitialAdUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdInterstitialUnitID") as? String ?? ""
    }

    static var appLovinInterstitialAdUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AppLovinInterstitialUnitID") as? String ?? ""
    }

    static var appLovinSDKKey: String {
        Bundle.main.object(forInfoDictionaryKey: "AppLovinSdkKey") as? String ?? ""
    }
}
