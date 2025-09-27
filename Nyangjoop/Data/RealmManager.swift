//
//  RealmManager.swift
//  TestTest
//
//  Created by Lee on 9/26/25.
//

import Foundation
import RealmSwift
import CoreLocation

final class RealmManager {

    static let shared = RealmManager()

    private let realm: Realm

    private init() {
        do {
            self.realm = try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error)")
        }
    }
}

extension RealmManager {
    func saveCat(_ cat: Cat) throws {
        try realm.write {
            realm.add(cat, update: .modified)
            print(realm.configuration.fileURL!)
        }
    }

    func fetchAllCats() -> Results<Cat> {
        return realm.objects(Cat.self)
    }

    func fetchCat(by id: ObjectId) -> Cat? {
        return realm.object(ofType: Cat.self, forPrimaryKey: id)
    }

    func deleteCat(_ cat: Cat) throws {
        try realm.write {
            realm.delete(cat.visitLogs)
            realm.delete(cat)
        }
    }

    func updateCat(_ cat: Cat, updates: @escaping (Cat) -> Void) throws {
        try realm.write {
            updates(cat)
        }
    }
}

extension RealmManager {

    func saveVisitLog(_ visitLog: VisitLog, to cat: Cat) throws {
        try realm.write {
            cat.visitLogs.append(visitLog)
        }
    }

    func addVisitLog(_ visitLog: VisitLog, toCatWithId catId: ObjectId) throws {
        guard let cat = fetchCat(by: catId) else {
            throw NSError(domain: "addVisitlog에러", code: 404)
        }

        try realm.write {
            cat.visitLogs.append(visitLog)
        }
    }

    func fetchVisitLogs(for cat: Cat) -> List<VisitLog> {
        return cat.visitLogs
    }

    func getVisitCount(for cat: Cat) -> Int {
        return cat.visitLogs.count
    }

    func fetchAllVisitLogs() -> Results<VisitLog> {
        return realm.objects(VisitLog.self).sorted(byKeyPath: "date", ascending: false)
    }

    func deleteVisitLog(_ visitLog: VisitLog) throws {
        try realm.write {
            realm.delete(visitLog)
        }
    }

    func getVisitCount() -> Int {
        return fetchAllVisitLogs().count
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
