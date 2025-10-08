//
//  RealmManager.swift
//  TestTest
//
//  Created by Lee on 9/26/25.
//

import Foundation
import RealmSwift
import CoreLocation

import Foundation
import RealmSwift

// MARK: - RealmManager

final class RealmManager {
    static let shared = RealmManager()
    private init() { }

    private func newRealm() throws -> Realm { try Realm() }

}

// MARK: - Cats

extension RealmManager {

    /// 생성/업서트
    func saveCat(_ cat: Cat) throws {
        let realm = try newRealm()
        try realm.write { realm.add(cat, update: .modified) }
    }

    /// 전체 조회 (스냅샷)
    func fetchAllCats() -> [Cat] {
        guard let realm = try? newRealm() else { return [] }
        return Array(realm.objects(Cat.self))
    }

    /// 단건 조회 (주의: 반환되는 객체는 호출 스레드의 Realm에 속함)
    func fetchCat(by id: ObjectId) -> Cat? {
        guard let realm = try? newRealm() else { return nil }
        return realm.object(ofType: Cat.self, forPrimaryKey: id)
    }

    /// 업데이트 (ID 기반, 내부에서 객체를 resolve)
    func updateCat(by id: ObjectId, updates: (Cat) -> Void) throws {
        let realm = try newRealm()
        guard let cat = realm.object(ofType: Cat.self, forPrimaryKey: id) else { return }
        try realm.write { updates(cat) }
    }

    /// 삭제 (연쇄 삭제 포함)
    func deleteCat(by id: ObjectId) throws {
        let realm = try newRealm()
        guard let cat = realm.object(ofType: Cat.self, forPrimaryKey: id), !cat.isInvalidated else { return }

        try realm.write {
            let visitLogs = Array(cat.visitLogs)
            
            for log in visitLogs where !log.isInvalidated {
                _ = FileManager.deleteImage(fileName: log.filePath)
            }
            
            realm.delete(visitLogs)
            realm.delete(cat)
        }
    }

    /// 기존 시그니처 유지용 (가능하면 위 ID 기반 사용 권장)
    func deleteCat(_ cat: Cat) throws {
        let realm = try newRealm()
        try realm.write {
            realm.delete(cat.visitLogs)
            realm.delete(cat)
        }
    }
}

// MARK: - VisitLogs

extension RealmManager {

    // Create
    func saveVisitLog(_ visitLog: VisitLog, toCatId catId: ObjectId) throws {
        let realm = try newRealm()
        guard let cat = realm.object(ofType: Cat.self, forPrimaryKey: catId) else {
            throw NSError(domain: "VisitLog", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Cat not found"])
        }
        try realm.write { cat.visitLogs.append(visitLog) }
    }

    // Read (Cat별)
    func fetchVisitLogs(forCatId catId: ObjectId) -> [VisitLog] {
        guard let realm = try? newRealm(),
              let cat = realm.object(ofType: Cat.self, forPrimaryKey: catId) else { return [] }
        return Array(cat.visitLogs.sorted(by: \.date, ascending: false))
    }

    // Read (전체)
    func fetchAllVisitLogs() -> [VisitLog] {
        guard let realm = try? newRealm() else { return [] }
        return Array(realm.objects(VisitLog.self).sorted(byKeyPath: "date", ascending: false))
    }

    // Count (Cat별)
    func getVisitCount(forCatId catId: ObjectId) -> Int {
        guard let realm = try? newRealm(),
              let cat = realm.object(ofType: Cat.self, forPrimaryKey: catId) else { return 0 }
        return cat.visitLogs.count
    }

    // Count (전체)
    func getVisitCount() -> Int {
        guard let realm = try? newRealm() else { return 0 }
        return realm.objects(VisitLog.self).count
    }

    // Delete (PK 기반)
    func deleteVisitLog(withId id: ObjectId) throws {
        let realm = try newRealm()
        guard let log = realm.object(ofType: VisitLog.self, forPrimaryKey: id) else { return }
        try realm.write { realm.delete(log) }
    }
}

//extension RealmManager {
//    func saveAchievement(_ achievement: Achievement) throws {
//        try realm.write {
//            realm.add(achievement, update: .modified)
//        }
//    }
//
//    func fetchAllAchievements() -> Results<Achievement> {
//        return realm.objects(Achievement.self)
//    }
//
//    func fetchUnlockedAchievements() -> Results<Achievement> {
//        return realm.objects(Achievement.self).where {
//            $0.isUnlocked == true
//        }
//    }
//
//    func unlockAchievement(title: String) throws {
//        guard let achievement = realm.objects(Achievement.self).where({ $0.title == title }).first else {
//                return
//            }
//
//        try realm.write {
//            achievement.isUnlocked = true
//            achievement.achievedDate = Date()
//        }
//
////        UserProfile.shared.addTitle(title)
//    }
//
//    func checkAndUnlockAchievements() {
//        let catCount = fetchAllCats().count
//        let visitCount = getVisitCount()
//
//        if catCount >= 1 {
//            try? unlockAchievement(title: "첫 만남")
//        }
//
//        if visitCount >= 100 {
//            try? unlockAchievement(title: "사진 작가")
//        }
//
//        if catCount >= 10 {
//            try? unlockAchievement(title: "고양이 집사")
//        }
//    }
//}

//extension RealmManager {
//    func saveRescueReport(_ report: RescueReport) throws {
//        try realm.write {
//            realm.add(report, update: .modified)
//        }
//    }
//
//    func fetchAllRescueReports() -> Results<RescueReport> {
//        return realm.objects(RescueReport.self).sorted(byKeyPath: "reportDate", ascending: false)
//    }
//
//    func getRescueReportCount() -> Int {
//        return fetchAllRescueReports().count
//    }
//}
//
//extension RealmManager {
//    struct CatStatistics {
//        let totalCats: Int
//        let totalVisits: Int
//        let averageVisitsPerCat: Double
//        let mostVisitedCat: Cat?
//        let recentVisits: [VisitLog]
//        let genderDistribution: [CatGender: Int]
//        let characterDistribution: [CatCharacter: Int]
//    }
//
//    func getCatStatistics() -> CatStatistics {
//         let cats = fetchAllCats()
//         let allVisits = fetchAllVisitLogs()
//
//         let totalCats = cats.count
//         let totalVisits = allVisits.count
//         let averageVisits = totalCats > 0 ? Double(totalVisits) / Double(totalCats) : 0
//
//         // 가장 많이 방문한 고양이
//         let mostVisitedCat = cats.max { cat1, cat2 in
//             cat1.visitCount < cat2.visitCount
//         }
//
//         // 최근 방문 5개
//         let recentVisits = Array(allVisits.prefix(5))
//
//         // 성별 분포
//         var genderDistribution: [CatGender: Int] = [:]
//         for cat in cats {
//             let gender = cat.genderEnum
//             genderDistribution[gender, default: 0] += 1
//         }
//
//         // 성격 분포
//         var characterDistribution: [CatCharacter: Int] = [:]
//         for cat in cats {
//             if let character = cat.characterEnum {
//                 characterDistribution[character, default: 0] += 1
//             }
//         }
//
//         return CatStatistics(
//             totalCats: totalCats,
//             totalVisits: totalVisits,
//             averageVisitsPerCat: averageVisits,
//             mostVisitedCat: mostVisitedCat,
//             recentVisits: recentVisits,
//             genderDistribution: genderDistribution,
//             characterDistribution: characterDistribution
//         )
//     }
//}
