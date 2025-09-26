//
//  ViewModelProtocol.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import Foundation

protocol ViewModelProtocol {
    associatedtype Input
    associatedtype Output

    func transform(_ input: Input) -> Output
}
