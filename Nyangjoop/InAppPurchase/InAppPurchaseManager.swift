//
//  UIViewController+Extension.swift
//  Nyangjoop
//
//  Created by Lee on 10/17/25.
//

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

    // 멱등(중복 지급 방지)용 로컬 캐시
    private let processedKey = "iap.processedTxIds"

    private init() {
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func loadProducts() async throws {
        let productIDs = [
            "com.jean.Nyangjoop.Chur10",
            "com.jean.Nyangjoop.Chur100",
            "com.jean.Nyangjoop.Chur1000"
        ]
        
        products = try await Product.products(for: productIDs)
    }
    
    func getProduct(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }
    
    func purchase(_ product: Product) async throws -> Int {
        let token = UserDefaults.standard.appAccountToken

        // 토큰을 결제 요청에 첨부
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
                    _ = self.redeemLocallyIfNeeded(transaction)
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


    private func addChur(_ amount: Int) {

        print("CHUR + \(amount)개")
    }

    private func getChurAmount(for productID: String) -> Int {
        switch productID {
        case "com.jean.Nyangjoop.Chur10":
            return 10
        case "com.jean.Nyangjoop.Chur100":
            return 100
        case "com.jean.Nyangjoop.Chur1000":
            return 1000
        default:
            return 0
        }
    }
}
