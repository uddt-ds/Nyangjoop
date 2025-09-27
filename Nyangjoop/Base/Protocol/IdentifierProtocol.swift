//
//  identifierProtocol.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import Foundation

protocol IdentifierProtocol {
    static var identifier: String { get }
}

extension IdentifierProtocol {
    static var identifier: String {
        return String(describing: Self.self)
    }
}
