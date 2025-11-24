import Foundation

/**
 A history database represents the interface to store and retrieve information about models and their data,
 including previous values.

 A database has three functions:
 - Write a value for a property of a model instance
 - Get a value for a property
 - Select all instances of a model with a specific property key
 */
public protocol TimestampedDatabase: Database {

    // MARK: Properties

    /**
     Get the value for a specific property.
     - Parameter path: The path of the property
     - Parameter date: The date at which the value is requested, `nil` indicates the most recent value.
     - Returns: The value of the property, if one exists
     */
    func get<Value: DatabaseValue>(_ path: Path) -> (value: Value, date: Date)?

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The path of the property
     - Parameter date: The date with which the value is associated, `nil` indicates the current time.
     */
    func set<Value: DatabaseValue>(_ value: Value, for path: Path, at date: Date?)

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
        where predicate: (_ instance: InstanceKey, _ status: InstanceStatus, _ date: Date) -> T?
    ) -> [T]
}
