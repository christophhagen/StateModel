import Foundation

/**
 An abstract class to subclass when implementing a state database that can store a history of each property.
 - Warning: All required functions of the `HistoryDatabaseProtocol` must be overwritten in subclasses.
 */
open class HistoryDatabase<ModelKey,InstanceKey,PropertyKey>: Database<ModelKey,InstanceKey,PropertyKey>, HistoryDatabaseProtocol where ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType {

    /**
     Create a database.
     */
    public override init() { }

    /**
     Get the value for a specific property.
     - Parameter path: The path of the property
     - Parameter date: The date at which the value is requested, `nil` indicates the most recent value.
     - Returns: The value of the property, if one exists
     */
    open func get<Value>(_ path: KeyPath, at date: Date?) -> (value: Value, date: Date)? where Value: DatabaseValue {
        fatalError()
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The path of the property
     - Parameter date: The date with which the value is associated, `nil` indicates the current time.
     */
    open func set<Value>(_ value: Value, for path: KeyPath, at date: Date?) where Value: DatabaseValue {
        fatalError()
    }

    /**
     Provide specific properties in the database to a conversion function.

     This function must provide all properties in the database that:
     - match the given model id
     - match the `PropertyKey.instanceId`
     - are of type `InstanceStatus`

     This function is used to select all instances of a model with specific properties.
     - Parameter model: The model id to match
     - Parameter date: The date for which the values are requested. `nil` indicates the current time.
     - Parameter predicate: The conversion function to call for each result of the search
     - Parameter instance: The instance id of the path that contained the `status`
     - Parameter status: The instance status of the path.
     - Parameter date: The timestamp of the instance status
     - Returns: The list of all search results that were returned by the `predicate`
     */
    open func all<T>(
        model: ModelKey,
        at date: Date?,
        where predicate: (_ instance: InstanceKey, _ status: InstanceStatus, _ date: Date) -> T?
    ) -> [T] {
        fatalError()
    }

    // MARK: Database functions

    /**
     Get the value for a specific property.
     - Parameter path: The path of the property
     - Returns: The value of the property, if one exists
     */
    public override func get<Value>(_ path: KeyPath) -> Value? where Value: DatabaseValue {
        guard let data: (value: Value, date: Date) = get(path, at: nil) else {
            return nil
        }
        return data.value
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The path of the property
     */
    public override func set<Value>(_ value: Value, for path: KeyPath) where Value: DatabaseValue {
        set(value, for: path, at: nil)
    }

    /**
     Provide specific properties in the database to a conversion function.

     This function must provide all properties in the database that:
     - match the given model id
     - match the `PropertyKey.instanceId`
     - are of type `InstanceStatus`

     This function is used to select all instances of a model with specific properties.
     - Parameter model: The model id to match
     - Parameter predicate: The conversion function to call for each result of the search
     - Parameter instance: The instance id of the path that contained the `status`
     - Parameter status: The instance status of the path.
     - Returns: The list of all search results that were returned by the `predicate`
     */
    public override func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus) -> T?) -> [T] {
        all(model: model, at: nil) { instance, status, _ in
            predicate(instance, status)
        }
    }
}
