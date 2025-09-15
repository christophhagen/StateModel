import Foundation

/**
 A history database represents the interface to store and retrieve information about models and their data,
 including previous values.

 A database has three functions:
 - Write a value for a property of a model instance
 - Get a value for a property
 - Select all instances of a model with a specific property key
 */
public protocol HistoryDatabaseProtocol: DatabaseProtocol {

    // MARK: Properties

    /**
     Get the value for a specific property.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     - Parameter date: The date at which the value is requested, `nil` indicates the most recent value.
     - Returns: The value of the property, if one exists
     */
    func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey, at date: Date?) -> (value: Value, date: Date)? where Value: DatabaseValue

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter date: The date with which the value is associated, `nil` indicates the current time.
     - Parameter property: The unique identifier of the property
     */
    func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey, at date: Date?) where Value: DatabaseValue

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
    func all<T>(
        model: ModelKey,
        at date: Date?,
        where predicate: (_ instance: InstanceKey, _ status: InstanceStatus, _ date: Date) -> T?
    ) -> [T]
}

extension HistoryDatabaseProtocol {

    /**
     Get the value for a specific property.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     - Returns: The value of the property, if one exists
     */
    public func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey) -> Value? where Value: DatabaseValue {
        get(model: model, instance: instance, property: property, at: nil)?.value
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     */
    public func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey) where Value: DatabaseValue {
        set(value, model: model, instance: instance, property: property, at: nil)
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
    public func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus) -> T?) -> [T] {
        all(model: model, at: nil) { instance, status, _ in
            predicate(instance, status)
        }
    }
}
