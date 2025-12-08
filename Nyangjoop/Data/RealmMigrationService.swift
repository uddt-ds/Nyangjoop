//
//  RealmMigrationService.swift
//  Nyangjoop
//
//  Created by Lee on 12/8/25.
//

import RealmSwift

final class RealmMigrationService {
    static let currentSchemaVersion: UInt64 = 1

    static func getConfiguration() -> Realm.Configuration {
        return Realm.Configuration(
            schemaVersion: currentSchemaVersion) { migration, oldSchemaVersion in
                performMigration(migration: migration, oldVersion: oldSchemaVersion)
            }
    }

    private static func performMigration(migration: Migration, oldVersion: UInt64) {
        if oldVersion < 1 {
            migrateToVersion1(migration)
        }
    }

    private static func migrateToVersion1(_ migration: Migration) {
        // 추가된 필드 및 변경사항
    }
}
