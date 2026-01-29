import Foundation
import SwiftData

enum SchemaVersions {
    enum V1: VersionedSchema {
        static var versionIdentifier = Schema.Version(1, 0, 0)
        static var models: [any PersistentModel.Type] {
            [
                MeetingRecord.self,
                Note.self,
                Person.self,
                EmbeddingRecord.self,
                Tag.self
            ]
        }
    }
}

enum PlannerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaVersions.V1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
