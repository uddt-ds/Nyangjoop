import UIKit
import StoreKit
import Toast

protocol ChurShopViewModelDelegate: AnyObject {
    func showRewardSuccess(churCount: Int)
    func showPurchaseSuccess(churCount: Int)
    func showError(message: String)
    func showToast(message: String)
    func adDidLoad()
    func updateAdCell()
}

final class ChurShopViewModel {
    weak var delegate: ChurShopViewModelDelegate?

    private let adManager = RewardAdManager.shared
    private let churService = ChurService.shared
    private let purchaseManager = InAppPurchaseManager.shared
    private let adTracker = RewardAdTracker.shared

    var currentChurCount: Int {
        return churService.currentChurCount
    }
    
    var canShowAd: Bool {
        return adTracker.canShowAd
    }
    
    var remainingAds: Int {
        return adTracker.remainingAds
    }

    init() {
        adManager.delegate = self
        
        Task {
            await loadProducts()
        }
    }

    func loadRewardAd() {
        adManager.loadAd(with: AdConfig.rewardedAdUnitID)
    }

    func showRewardAd(from viewController: UIViewController) {
        guard canShowAd else {
            delegate?.showError(message: "오늘은 더 이상 광고를 볼 수 없어요")
            return
        }
        
        guard adManager.isAdReady else {
            loadRewardAd()
            return
        }

        adManager.showAd(from: viewController)
    }

    var isReady: Bool {
        return adManager.isAdReady
    }
    
    private func loadProducts() async {
        do {
            try await purchaseManager.loadProducts()
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchaseProduct(productID: String) {
        Task {
            do {
                guard let product = purchaseManager.getProduct(for: productID) else {
                    await MainActor.run {
                        delegate?.showError(message: "제품을 찾을 수 없습니다.")
                    }
                    return
                }
                
                _ = try await purchaseManager.purchase(product)
                
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("ChurCountUpdated"), object: nil)
                    delegate?.showPurchaseSuccess(churCount: churService.currentChurCount)
                }
                
            } catch let error as PurchaseError {
                await MainActor.run {
                    if error != .userCancelled {
                        delegate?.showError(message: error.localizedDescription)
                    }
                }
            } catch {
                await MainActor.run {
                    delegate?.showError(message: "구매 중 오류가 발생했습니다.")
                }
            }
        }
    }
}

extension ChurShopViewModel: RewardAdManagerDelegate {
    func rewardAdDidLoad() {
        print("광고 로드 완료")
        delegate?.adDidLoad()
    }
    
    func rewardAdDidFailToLoad(with error: any Error) {
        delegate?.showToast(message: "광고를 불러올 수 없습니다")
    }
    
    func rewardAdDidPresent() {
        print("광고 표시 시작")
    }
    
    func rewardAdDidDismiss() {
        loadRewardAd()
    }

    func rewardAdDidFail(with error: any Error) {
        delegate?.showError(message: "광고 재생 중 오류가 발생했습니다")
    }
    
    func userDidEarnReward(amount: Int) {
        print("[ChurShopViewModel] 보상 받음 - 원래 amount: \(amount)")
        print("[ChurShopViewModel] 츄르 추가 전: \(churService.currentChurCount)")
        
        let churToAdd = 1
        churService.addChur(amount: churToAdd)
        
        adTracker.incrementAdCount()
        
        print("[ChurShopViewModel] 츄르 추가 후: \(churService.currentChurCount)")
        print("[ChurShopViewModel] 남은 광고 횟수: \(adTracker.remainingAds)")
        
        NotificationCenter.default.post(name: NSNotification.Name("ChurCountUpdated"), object: nil)
        
        delegate?.showRewardSuccess(churCount: churService.currentChurCount)
        delegate?.updateAdCell()
    }
}
