//
//  RealmModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import UIKit
import RealmSwift

final class Cat: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String
    @Persisted var meetDate: Date
    @Persisted var gender: Int
    @Persisted var character: Int?
    @Persisted var drawImage: String
    @Persisted var lat: Double
    @Persisted var lon: Double
    @Persisted var visitLogs: List<VisitLog>

    convenience init(name: String, meetDate: Date, gender: Int, character: Int? = nil, drawImage: String, lat: Double, lon: Double) {
        self.init()
        self.name = name
        self.meetDate = meetDate
        self.gender = gender
        self.character = character
        self.drawImage = drawImage
        self.lat = lat
        self.lon = lon
    }

    var genderEnum: CatGender {
        return CatGender(rawValue: gender) ?? .unknown
    }

    var characterEnum: CatCharacter? {
        guard let character = character else { return nil }
        return CatCharacter(rawValue: character)
    }

    var visitCount: Int {
        return visitLogs.count
    }

    var firstVisitDate: Date? {
        return visitLogs.sorted(byKeyPath: "date", ascending: false).first?.date
    }

    var lastVisitDate: Date? {
        return visitLogs.sorted(byKeyPath: "date", ascending: false).last?.date
    }

    func getDisplayImage(forGalleryMode: Bool) -> UIImage? {

        let actualPhoto = getFirstVisitPhoto()
        let defaultImage = !drawImage.isEmpty ? UIImage(named: drawImage) : nil

        if forGalleryMode {
            return defaultImage ?? actualPhoto
        } else {
            return actualPhoto ?? defaultImage
        }
    }

    private func getFirstVisitPhoto() -> UIImage? {
        guard let firstVisit = visitLogs.first else {
            return nil
        }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagePath = documentsPath.appending(path: firstVisit.filePath)

        let image = UIImage(contentsOfFile: imagePath.path())
        return image
    }
}

final class VisitLog: Object {
    @Persisted(primaryKey: true) var id: ObjectId

    @Persisted var date: Date
    @Persisted var filePath: String
    @Persisted var memo: String?
    @Persisted var lat: Double
    @Persisted var lon: Double

    @Persisted(originProperty: "visitLogs")
    var parentCat: LinkingObjects<Cat>

    var cat: Cat? {
        return parentCat.first
    }

    convenience init(catId: ObjectId, date: Date, filePath: String, memo: String? = nil, lat: Double, lon: Double) {
        self.init()
        self.date = date
        self.filePath = filePath
        self.memo = memo
        self.lat = lat
        self.lon = lon
    }
}

enum CatGender: Int, CaseIterable {
    case male = 0   // 남아
    case female = 1  // 여아
    case unknown = 2  // 모름

    var displayName: String {
        switch self {
        case .male: return "남아"
        case .female: return "여아"
        case .unknown: return "모름"
        }
    }
}

enum CatCharacter: Int, CaseIterable {
    case unknown = 0     // 몰라
    case timid = 1     // 겁쟁이
    case friendly = 2     // 개냥이
    case grumpy = 3     // 까칠함
    case calm = 4        // 무던함
    case tsundere = 5     // 츤데레

    var displayName: String {
        switch self {
        case .timid:
            return "겁쟁이"
        case .friendly:
            return "개냥이"
        case .grumpy:
            return "까칠함"
        case .calm:
            return "무던함"
        case .tsundere:
            return "츤데레"
        case .unknown:
            return "몰라"
        }
    }
}
