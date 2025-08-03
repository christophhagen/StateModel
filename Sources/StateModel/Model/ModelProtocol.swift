import Foundation

/**
 A model represents the basic type to inherit from when defining models to store in the database.

 Assuming a type `MyDatabase` implements ``Database`` with a ``PathKey`` of type ``Int``,
 then a model for that database can be defined as:

 ```swift
 final class MyModel: Model<MyDatabase> {

     static let modelId = 1

     @Property(id: 42)
     var some: String
 }
 ```

 Here the `modelId` represents the unique identifier for `MyModel`, while `id` uniquely identifies the property `some`.
 When creating a type of `MyModel`, a unique id for the instance needs to be supplied as well:

 ```swift
 let database = MyDatabase(...)
 let instance: MyModel = database.create(id: 123)
 ```

 When now setting the property `some`, the database will be informed about the change:

 ```swift
 instance.some = "abc"
 ```

 The update has the form:

 ```
 (model: 1, instance: 123, property: 42, value: "abc")
 ```

 This record will be persisted by the database. When a property is accessed, then a request to the database is made:

 ```
 (model: 1, instance: 123, property: 42)
 ```

 The database will retrieve the current value ( `"abc"`) for the key path, and hand it to the instance:

 ```swift
 print(instance.some) // prints "abc"
 ```
 */
public typealias Model<S: Database> = BaseModel<S> & ModelProtocol

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

    /// The path to store or retrieve the instance
    var instancePath: Storage.KeyPath {
        Self.instance(id: id)
    }

    /**
     Access the path to a specific instance
     */
    static func instance(id: Storage.InstanceKey) -> Storage.KeyPath {
        .init(model: modelId, instance: id)
    }
}

extension ModelProtocol {

    /**
     Retrieve the current status of the instance from the database.
     */
    public var status: InstanceStatus {
        database.get(instancePath) ?? .created
    }

    /**
     Delete the instance from the database.

     This function has no effect for deleted and non-existant instances.
     */
    public func delete() {
        guard let status: InstanceStatus = database.get(instancePath), status == .created else { return }
        database.delete(self)
    }

    /**
     Insert a previously deleted model.

     This function has no effect for non-deleted instances.
     */
    public func insert() {
        guard status == .deleted else { return }
        database.set(InstanceStatus.created, for: instancePath)
    }
}
