
/**
 A database represents the interface to store and retrieve information about models and their data.

 A database has three functions:
 - Write a value for a property of a model instance
 - Get a value for a property
 - Select all instances of a model with a specific property key
 */
public protocol Database: AnyObject {

    // MARK: Properties

    /**
     Get the value for a specific property.
     - Parameter path: The path of the property
     - Returns: The value of the property, if one exists
     */
    func get<Value>(_ path: Path) -> Value? where Value: DatabaseValue

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The path of the property
     */
    func set<Value>(_ value: Value, for path: Path) where Value: DatabaseValue

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
    func all<T>(model: ModelKey, where predicate: (_ instance: Int, _ status: InstanceStatus) -> T?) -> [T]

    // MARK: Default implementations

    /**
     Create a new instance.

     This function will set the instance status of the provided id to `created`,
     and return the instance.

     - Parameter id: The instance id
     - Parameter type: The type of model to create.
     - Returns: A new model instance of the specified type with the given id.
     */
    func create<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    func get<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance?

    /**
     Get an instance via its id, if it exists and is not deleted.
     - Parameter id: The instance id
     - Parameter type: The type of the model
     - Returns: The existing, non-deleted instance, or `nil`
     */
    func active<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance?

    /**
     Delete a specific instance.
     - Parameter instance: The instance to delete
     */
    func delete<Instance: ModelProtocol>(_ instance: Instance)

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    func all<Instance: ModelProtocol>(where predicate: (Instance) -> Bool) -> [Instance]
}
