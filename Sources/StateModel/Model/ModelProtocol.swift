import Foundation

/**
 A type that can be represented by a key path structure
 */
public protocol ModelProtocol: ModelInstance, ObservableObject {

    /**
     The unique ID of this model class when used in a key path.

     The model id is the first part of a key path.
     */
    static var modelId: ModelKey { get }

}

extension ModelProtocol {

    @inline(__always)
    func get<T: DatabaseValue>(_ property: PropertyKey, of type: T.Type = T.self) -> T? {
        database.get(model: Self.modelId, instance: id, property: property)
    }

    @inline(__always)
    func set<T: DatabaseValue>(_ value: T, for property: PropertyKey, of type: T.Type = T.self) {
        database.set(value, model: Self.modelId, instance: id, property: property)
    }

    public func all(in database: Database) -> [Self] {
        database.all(model: Self.modelId) { instanceId, status in
            guard status == .created else {
                return nil
            }
            return Self(database: database, id: instanceId)
        }
    }

    /**
     Retrieve the current status of the instance from the database.
     */
    public var status: InstanceStatus {
        self.get(PropertyKey.instanceId) ?? .created
    }

    /**
     Delete the instance from the database.

     This function has no effect for deleted and non-existant instances.
     */
    public func delete() {
        guard let status: InstanceStatus = get(PropertyKey.instanceId), status == .created else { return }
        set(InstanceStatus.deleted, for: PropertyKey.instanceId)
    }

    /**
     Insert a previously deleted model.

     This function has no effect for non-deleted instances.
     */
    public func insert() {
        guard status == .deleted else { return }
        set(InstanceStatus.created, for: PropertyKey.instanceId)
    }
}
