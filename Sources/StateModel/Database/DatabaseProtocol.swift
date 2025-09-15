
/**
 A database represents the interface to store and retrieve information about models and their data.

 A database has three functions:
 - Write a value for a property of a model instance
 - Get a value for a property
 - Select all instances of a model with a specific property key
 */
public protocol DatabaseProtocol: AnyObject {

    /// The type used to uniquely identify different model types in the database
    associatedtype ModelKey: ModelKeyType

    /// The type used to uniquely identify each instance of a model in the database
    associatedtype InstanceKey: InstanceKeyType

    /// The type used to uniquely identify the properties of models in the database
    associatedtype PropertyKey: PropertyKeyType

    /// The type that identifies each property of a model instance uniquely
    typealias KeyPath = Path<ModelKey, InstanceKey, PropertyKey>

    // MARK: Properties

    /**
     Get the value for a specific property.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     - Returns: The value of the property, if one exists
     */
    func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey) -> Value? where Value: DatabaseValue

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     */
    func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey) where Value: DatabaseValue

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
    func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus) -> T?) -> [T]
}
