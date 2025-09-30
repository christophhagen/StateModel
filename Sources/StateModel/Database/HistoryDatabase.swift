import Foundation

extension HistoryDatabase {

    // MARK: Database functions

    /**
     Get the value for a specific property.
     - Parameter path: The path of the property
     - Returns: The value of the property, if one exists
     */
    public func get<Value>(_ path: Path) -> Value? where Value: DatabaseValue {
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
    public func set<Value>(_ value: Value, for path: Path) where Value: DatabaseValue {
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
    public func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus) -> T?) -> [T] {
        all(model: model, at: nil) { instance, status, _ in
            predicate(instance, status)
        }
    }
}
