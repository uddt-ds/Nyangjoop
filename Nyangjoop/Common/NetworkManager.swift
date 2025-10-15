//
//  NetworkManager.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa

final class NetworkManager {
    static let shared = NetworkManager()

    private init() { }

    func fetchData(lat: Double, lon: Double) -> Single<Result<[MarketModel], NetworkError>> {
        return Single.create { observer in
            guard let headerKey = Bundle.main.object(forInfoDictionaryKey: "apiKey") as? String else {
                print("API 키 없음")
                observer(.success(.failure(.unknown)))
                return Disposables.create()
            }

            let parameters: Parameters = [
                "query": "반려동물간식",
                "x": lon,
                "y": lat,
                "radius": 2000
            ]

            guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
                print("baseURL 오류")
                return Disposables.create()
            }

            let url = "https://" + baseURL + "/v2/local/search/keyword"

            print("요청 파라미터: \(parameters)")

            let request = AF.request(
                url,
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: ["Authorization": "\(headerKey)"]
            )
            .responseDecodable(of: MarketModelDTO.self) { response in
                print("응답 상태코드: \(response.response?.statusCode ?? 0)")

                if let url = response.request?.url?.absoluteString {
                    print("\(url)")
                }

                if let data = response.data, let str = String(data: data, encoding: .utf8) {
                    print("응답 데이터: \(str)")
                }



                switch response.result {
                case .success(let data):
                    print("성공: \(data.documents.count)개 장소")
                    observer(.success(.success(data.toDomain())))
                case .failure(let error):
                    print("실패 상세: \(error)")
                    if let afError = error.asAFError {
                        switch afError {
                        case .responseSerializationFailed(let reason):
                            print("직렬화 실패: \(reason)")
                        default:
                            print("AF 에러: \(afError)")
                        }
                    }
                    observer(.success(.failure(.failDecoding)))
                }
            }

            return Disposables.create {
                request.cancel()
            }
        }
    }

}


enum NetworkError: Error {
    case invalidUrl
    case failDecoding
    case noData
    case unknown

    var message: String {
        switch self {
        case .invalidUrl:
            "잘못된 URL입니다"
        case .failDecoding:
            "디코딩 실패"
        case .noData:
            "데이터가 없습니다"
        case .unknown:
            "알 수 없는 오류"
        }
    }
}
