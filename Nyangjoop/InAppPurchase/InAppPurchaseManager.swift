//
//  UIViewController+Extension.swift
//  Nyangjoop
//
//  Created by Lee on 10/17/25.
//

import Foundation
import StoreKit

import Foundation
import StoreKit

enum PurchaseError: Error {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case pending

    var localizedDescription: String {
        switch self {
        case .productNotFound:
            return "제품을 찾을 수 없습니다."
        case .purchaseFailed:
            return "구매에 실패했습니다."
        case .verificationFailed:
            return "구매 검증에 실패했습니다."
        case .userCancelled:
            return "구매가 취소되었습니다."
        case .pending:
            return "구매가 대기 중입니다."
        }
    }
}

final class InAppPurchaseManager {
    static let shared = InAppPurchaseManager()

    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?

    private let processedKey = "iap.processedTxIds"

    private let adRemovalProductID = "com.jean.Nyangjoop.RemoveAds"
    private let adRemovalKey = "has_purchased_ad_removal"

    var hasRemovedAds: Bool {
        get {
            UserDefaults.standard.bool(forKey: adRemovalKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: adRemovalKey)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .adRemovalStatusChanged, object: nil)
            }
        }
    }

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await checkAdRemovalStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async throws {
        let productIDs = [
            "com.jean.Nyangjoop.Chur10",
            "com.jean.Nyangjoop.Chur100",
            "com.jean.Nyangjoop.RemoveAds"
        ]

        products = try await Product.products(for: productIDs)
    }

    func getProduct(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }

    func purchase(_ product: Product) async throws -> Int {
        if product.id == adRemovalProductID {
            return try await purchaseAdRemoval(product)
        }

        let token = UserDefaults.standard.appAccountToken
        let result = try await product.purchase(options: [.appAccountToken(token)])

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            print(transaction)
            print("appAccountToken", transaction.appAccountToken as Any)

            switch transaction.environment {
            case .xcode: print("Xcode 환경")
            case .sandbox: print("SandBox 환경")
            case .production: print("Production 환경")
            default: break
            }

            let didGrant = redeemLocallyIfNeeded(transaction)
            await transaction.finish()

            return didGrant ? getChurAmount(for: product.id) : 0

        case .userCancelled:
            throw PurchaseError.userCancelled

        case .pending:
            throw PurchaseError.pending

        @unknown default:
            throw PurchaseError.purchaseFailed
        }
    }

    private func purchaseAdRemoval(_ product: Product) async throws -> Int {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            hasRemovedAds = true
            await transaction.finish()
            return 0

        case .userCancelled:
            throw PurchaseError.userCancelled

        case .pending:
            throw PurchaseError.pending

        @unknown default:
            throw PurchaseError.purchaseFailed
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkAdRemovalStatus()
    }

    private func checkAdRemovalStatus() async {
        guard let product = try? await Product.products(for: [adRemovalProductID]).first else {
            return
        }

        guard let state = await product.currentEntitlement else {
            hasRemovedAds = false
            return
        }

        switch state {
        case .verified:
            hasRemovedAds = true
        case .unverified:
            hasRemovedAds = false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Transaction 검사할 때 환불 상태 확인
                    if self.checkRefund(transaction) {
                        await MainActor.run {
                            self.handleRefund(transaction)
                        }
                        await transaction.finish()
                        continue
                    }

                    if transaction.productID == self.adRemovalProductID {
                        await MainActor.run {
                            self.hasRemovedAds = true
                        }
                    } else {
                        _ = self.redeemLocallyIfNeeded(transaction)
                    }

                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func redeemLocallyIfNeeded(_ tx: Transaction) -> Bool {
        let id = String(tx.id)
        var set = Set(UserDefaults.standard.stringArray(forKey: processedKey) ?? [])
        guard set.contains(id) == false else { return false }

        let amount = getChurAmount(for: tx.productID)
        ChurService.shared.addChur(amount: amount)

        set.insert(id)
        UserDefaults.standard.processedTxIds = set
        return true
    }

    private func getChurAmount(for productID: String) -> Int {
        switch productID {
        case "com.jean.Nyangjoop.Chur10":
            return 10
        case "com.jean.Nyangjoop.Chur100":
            return 100
        default:
            return 0
        }
    }

    // MARK: 환불 관련 로직 추가
    private func checkRefund(_ transaction: Transaction) -> Bool {
        return transaction.revocationDate != nil     // nil이 아니면 환불된 거래
    }

    private func handleRefund(_ transaction: Transaction) {
        let id = String(transaction.id)

        var set = Set(UserDefaults.standard.stringArray(forKey: processedKey) ?? [])
        set.remove(id)
        UserDefaults.standard.processedTxIds = set

        // 츄르 차감(소모성 제품)
        if transaction.productID != adRemovalProductID {
            let amount = getChurAmount(for: transaction.productID)
            ChurService.shared.addChur(amount: -amount)
        } else {
            // 광고 제거 환불 시 상태 복원
            hasRemovedAds = false
        }
    }

    // 환불 요청 API(앱 내에서 시트 형태로 present)
    private func requestRefund(for transaction: Transaction) async throws {
        guard let scene = UIApplication.shared.connectedScnenes.first as? UIWindowScene else {
            return
        }

        do {
            let status = try await transaction.beginRefundRequest(in: scene)

            switch status {
            case .success:
                print("환불 요청이 제출되었습니다")
            case .userCancelled:
                print("환불 요청을 취소했습니다")
            @unknown default:
                break
            }
        } catch {
            print("환불 요청 중 오류 발생: \(error)")
        }
    }
}

extension Notification.Name {
    static let adRemovalStatusChanged = Notification.Name("adRemovalStatusChanged")
}
