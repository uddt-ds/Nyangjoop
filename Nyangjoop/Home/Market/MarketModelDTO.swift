//
//  MarketModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import Foundation

struct MarketModelDTO: Decodable {
    let documents: [DocumentsDTO]

    func toDomain() -> [MarketModel] {
        return documents.map { $0.toDomain() }
    }
}

struct DocumentsDTO: Decodable {
    let address_name: String
    let category_group_code: String
    let category_group_name: String
    let category_name: String
    let distance: String
    let id: String
    let phone: String
    let place_name: String
    let place_url: String
    let road_address_name: String
    let x: String
    let y: String

    func toDomain() -> MarketModel {
        return .init(addressName: address_name,
                     placeName: place_name,
                     roadAddressName: road_address_name,
                     x: Double(x) ?? 0
                     , y: Double(y) ?? 0)
    }
}

struct MarketModel {
    let addressName: String
    let placeName: String
    let roadAddressName: String
    let x: Double
    let y: Double
}
