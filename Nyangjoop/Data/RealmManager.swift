//
//  RealmManager.swift
//  TestTest
//
//  Created by Lee on 9/26/25.
//

import Foundation
import RealmSwift
import CoreLocation

// MARK: - RealmManager

final class RealmManager {
    static let shared = RealmManager()
    private init() { }

    func getRealm() throws -> Realm {
        return try newRealm()
    }
    
    private func newRealm() throws -> Realm {
        return try Realm(configuration: RealmMigrationService.getConfiguration())
    }

}

// MARK: - Cats

extension RealmManager {

    func saveCat(_ cat: Cat) throws {
        let realm = try newRealm()
        try realm.write { realm.add(cat, update: .modified) }
        WidgetSyncManager.updateWidgetStatsFromRealm()
    }

    func fetchAllCats() -> [Cat] {
        guard let realm = try? newRealm() else { return [] }
        return Array(realm.objects(Cat.self))
    }

    func fetchCat(by id: ObjectId) -> Cat? {
        guard let realm = try? newRealm() else { return nil }
        return realm.object(ofType: Cat.self, forPrimaryKey: id)
    }

    func updateCat(by id: ObjectId, updates: (Cat) -> Void) throws {
        let realm = try newRealm()
        guard let cat = realm.object(ofType: Cat.self, forPrimaryKey: id) else { return }
        try realm.write { updates(cat) }
    }

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
        WidgetSyncManager.updateWidgetStatsFromRealm()
    }

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

    func saveVisitLog(_ visitLog: VisitLog, toCatId catId: ObjectId) throws {
        let realm = try newRealm()
        guard let cat = realm.object(ofType: Cat.self, forPrimaryKey: catId) else {
            throw NSError(domain: "VisitLog", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Cat not found"])
        }
        try realm.write { cat.visitLogs.append(visitLog) }
        WidgetSyncManager.updateWidgetStatsFromRealm()
    }

    func fetchVisitLogs(forCatId catId: ObjectId) -> [VisitLog] {
        guard let realm = try? newRealm(),
              let cat = realm.object(ofType: Cat.self, forPrimaryKey: catId) else { return [] }
        return Array(cat.visitLogs.sorted(by: \.date, ascending: false))
    }

    func fetchAllVisitLogs() -> [VisitLog] {
        guard let realm = try? newRealm() else { return [] }
        return Array(realm.objects(VisitLog.self).sorted(byKeyPath: "date", ascending: false))
    }

    func getVisitCount(forCatId catId: ObjectId) -> Int {
        guard let realm = try? newRealm(),
              let cat = realm.object(ofType: Cat.self, forPrimaryKey: catId) else { return 0 }
        return cat.visitLogs.count
    }

    func getVisitCount() -> Int {
        guard let realm = try? newRealm() else { return 0 }
        return realm.objects(VisitLog.self).count
    }

    func deleteVisitLog(withId id: ObjectId) throws {
        let realm = try newRealm()
        guard let log = realm.object(ofType: VisitLog.self, forPrimaryKey: id) else { return }
        try realm.write { realm.delete(log) }
    }
}

// MARK: - Statistics for Achievements

extension RealmManager {
    func getTotalCatCount() -> Int {
        guard let realm = try? newRealm() else { return 0 }
        return realm.objects(Cat.self).count
    }
    
    func getTotalPhotoCount() -> Int {
        guard let realm = try? newRealm() else { return 0 }
        return realm.objects(VisitLog.self).count
    }
}
