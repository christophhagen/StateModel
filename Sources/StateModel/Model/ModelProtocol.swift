import Foundation

/**
 A type that can be represented by a key path structure
 */
public protocol ModelProtocol: AnyObject {

    /**
     The database type to use with this model.

     It is necessary to couple each model implementation with a database, since it contains a reference to the database for updating.
     */
    associatedtype Storage: Database

    /**
     The unique ID of this model class when used in a key path.

     The model id is the first part of a key path.
     */
    static var modelId: Storage.ModelKey { get }

    /**
     The unique id of the instance.

     This id must be unique among all instances of the type.
     The id is used as the second part of the key path.
     */
    var id: Storage.InstanceKey { get }

    /**
     A reference to the database where the model is persisted.

     This reference should be `unowned` to not create retain cycles.
     */
    var database: Storage { get }

    /**
     Create a new instance.
     */
    init(database: Storage, id: Storage.InstanceKey)
}

extension ModelProtocol {

    /**
     Retrieve the current status of the instance from the database.
     */
    public var status: InstanceStatus {
        database.get(model: Self.modelId, instance: id, property: Storage.PropertyKey.instanceId) ?? .created
    }

    /**
     Delete the instance from the database.

     This function has no effect for deleted and non-existant instances.
     */
    public func delete() {
        guard let status: InstanceStatus = database.get(model: Self.modelId, instance: id, property: Storage.PropertyKey.instanceId), status == .created else { return }
        database.delete(self)
    }

    /**
     Insert a previously deleted model.

     This function has no effect for non-deleted instances.
     */
    public func insert() {
        guard status == .deleted else { return }
        database.set(InstanceStatus.created, model: Self.modelId, instance: id, property: Storage.PropertyKey.instanceId)
    }
}
